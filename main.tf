resource "aws_security_group" "security_group" {
  name        = lower("${var.service_name}-ecs")
  description = "${var.service_name} ECS service security group"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "permit_outbound_traffic" {
  type              = "egress"
  description       = "Permit access to 443 for ECR access"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.security_group.id
}

resource "aws_ecs_service" "service" {
  depends_on = [
    aws_iam_role.execution_role,
    aws_iam_role.task_role
  ] # Required to avoid a race condition during a service deletion (Documented in the terraform resource page)

  name    = var.service_name
  cluster = var.cluster_arn
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  enable_ecs_managed_tags            = true
  force_new_deployment               = true
  health_check_grace_period_seconds  = var.health_check_grace_period_in_seconds
  launch_type                        = "FARGATE"
  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.task_definition.entrypoint_container_name
    container_port   = var.task_definition.entrypoint_container_port
  }
  dynamic "load_balancer" {
    for_each = var.extra_target_groups
    content {
      target_group_arn = load_balancer.value
      container_name   = var.task_definition.entrypoint_container_name
      container_port   = var.task_definition.entrypoint_container_port
    }
  }
  network_configuration {
    subnets          = var.subnets
    security_groups  = [aws_security_group.security_group.id]
    assign_public_ip = false
  }
  propagate_tags  = "SERVICE"
  task_definition = aws_ecs_task_definition.task_definition.arn
  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  depends_on = [
    aws_ecs_service.service
  ]
  max_capacity       = var.autoscaling_configuration.max_capacity
  min_capacity       = var.autoscaling_configuration.min_capacity
  resource_id        = element(split(":", aws_ecs_service.service.id), length(split(":", aws_ecs_service.service.id)) - 1)
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy" {
  name               = "${var.service_name}ECSAutoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  target_tracking_scaling_policy_configuration {
    target_value = var.autoscaling_configuration.max_connections_per_container
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${trimprefix(local.load_balancer_id, "loadbalancer/")}/${local.target_group_id}"
    }
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

resource "aws_ecs_task_definition" "task_definition" {
  container_definitions    = jsonencode(var.container_definitions)
  cpu                      = var.cpu
  execution_role_arn       = aws_iam_role.execution_role.arn
  family                   = var.service_name
  memory                   = var.memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.task_role.arn
}
