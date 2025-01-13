data "aws_iam_policy_document" "execution_role_assume_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "execution_role_policy" {
  dynamic "statement" {
    for_each = { for key, value in var.execution_role_policies[0].statement : key => value }
    content {
      actions   = statement.value.Action
      effect    = statement.value.Effect
      resources = statement.value.Resource
    }
  }
  dynamic "statement" {
    for_each = length(var.ecr_repository_arns) != 0 ? [{ ecr_repository_arns : var.ecr_repository_arns }] : []
    content {
      effect = "Allow"
      actions = [
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
      resources = statement.value.ecr_repository_arns
    }
  }
}

resource "aws_iam_role" "execution_role" {
  name               = "${var.service_name}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.execution_role_assume_policy.json
}

resource "aws_iam_role_policy" "execution_role_custom_policy" {
  name   = "CustomPolicy"
  role   = aws_iam_role.execution_role.id
  policy = data.aws_iam_policy_document.execution_role_policy.json
}

resource "aws_iam_role_policy_attachment" "execution_role_ec2_container_service_policy" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

resource "aws_iam_role_policy_attachment" "execution_role_ecs_task_execution_policy" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "task_role_assume_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = try(concat(["ecs-tasks.amazonaws.com"], var.task_role_extra_allowed_principals.services), ["ecs-tasks.amazonaws.com"])
    }
    principals {
      type        = "AWS"
      identifiers = var.task_role_extra_allowed_principals.aws
    }
  }
}

data "aws_iam_policy_document" "task_role_policy" {
  count = lenght(var.task_role_policies) > 0 ? 1 : 0
  dynamic "statement" {
    for_each = { for key, value in var.task_role_policies[0].statement : key => value }
    content {
      actions   = statement.value.Action
      effect    = statement.value.Effect
      resources = statement.value.Resource
    }
  }
}

resource "aws_iam_role" "task_role" {
  name               = "${var.service_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.task_role_assume_policy.json
}

resource "aws_iam_role_policy" "task_role_custom_policy" {
  count  = lenght(var.task_role_policies) > 0 ? 1 : 0
  name   = "CustomPolicy"
  role   = aws_iam_role.task_role.id
  policy = data.aws_iam_policy_document.task_role_policy[0].json
}

resource "aws_iam_role_policy_attachment" "task_role_ecs_task_execution_policy" {
  role       = aws_iam_role.task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
