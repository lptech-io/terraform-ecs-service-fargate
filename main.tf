resource "aws_security_group" "security_group" {
  name        = lower("${var.service_name}-ecs")
  description = "${var.service_name} ECS service security group"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "permit_outbound_traffic" {
  type = "egress"
  description = "Permit access to 443 for ECR access"
  cidr_blocks = ["0.0.0.0/0"]
  from_port = 443
  to_port = 443
  protocol = "tcp"
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
  force_new_deployment               = true
  health_check_grace_period_seconds  = var.health_check_grace_period_in_seconds
  launch_type                        = "FARGATE"
  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.task_definition.entrypoint_container_name
    container_port   = var.task_definition.entrypoint_container_port
  }
  network_configuration {
    subnets          = var.subnets
    security_groups  = [aws_security_group.security_group.id]
    assign_public_ip = false
  }
  propagate_tags  = "TASK_DEFINITION"
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

resource "aws_iam_role" "execution_role" {
  name = "${var.service_name}-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole",
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
  ]
  dynamic "inline_policy" {
    for_each = var.execution_role_policies

    content {
      name = inline_policy.value.name
      policy = jsonencode({
        Version   = "2012-10-17",
        Statement = inline_policy.value.statement,
      })
    }
  }
  dynamic "inline_policy" {
    for_each = length(var.ecr_repository_arns) != 0 ? [{ ecr_repository_arns : var.ecr_repository_arns }] : []
    content {
      name = "ECRAccess"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "ecr:BatchCheckLayerAvailability",
              "ecr:BatchGetImage",
              "ecr:DescribeImages",
              "ecr:DescribeRepositories",
              "ecr:GetAuthorizationToken",
              "ecr:GetDownloadUrlForLayer",
              "ecr:GetRepositoryPolicy",
              "ecr:ListImages",
              "ecr:ListTagsForResource",
            ]
            Resource = inline_policy.value.ecr_repository_arns
          }
        ]
      })
    }
  }
}

resource "aws_iam_role" "task_role" {
  name = "${var.service_name}-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = concat(["ecs-tasks.amazonaws.com"], var.task_role_extra_allowed_principal.services)
          AWS = var.task_role_extra_allowed_principal.aws
        }
      },
    ]
  })
  dynamic "inline_policy" {
    for_each = var.task_role_policies
    content {
      name = inline_policy.value.name
      policy = jsonencode({
        Version   = "2012-10-17",
        Statement = inline_policy.value.statement,
      })
    }
  }
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
  ]
}
