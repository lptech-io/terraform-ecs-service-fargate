variable "autoscaling_configuration" {
  description = "Autoscaling configuration for ECS service"
  type = object({
    max_connections_per_container = optional(number, 500)
    max_capacity                  = number
    min_capacity                  = number
  })
}

variable "cluster_arn" {
  description = "The ECS cluster ARN"
  type        = string
}

variable "container_definitions" {
  description = "Container definitions for the ECS service"
  type = list(object({
    name   = string
    image  = string
    cpu    = optional(number)
    memory = optional(number)
    portMappings = optional(list(object({
      hostPort      = optional(number)
      containerPort = number
      protocol      = string
    })))
    essential  = optional(bool)
    entryPoint = optional(list(string))
    command    = optional(list(string))
    firelensConfiguration = optional(object({
      type = string
      options = object({
        config-file-type        = string
        enable-ecs-log-metadata = string
        config-file-value       = string
      })
    }))
    logConfiguration = optional(object({
      logDriver = string
      options   = optional(map(string))
    }))
    environment = optional(list(object({
      name  = string
      value = string
    })))
    secrets = optional(list(object({
      name      = string
      valueFrom = string
    })))
  }))
}

variable "cpu" {
  default     = 1024
  description = "The CPU units"
  type        = number
}

variable "ecr_repository_arns" {
  default     = []
  description = "The ECR repository ARNs"
  type        = list(string)
}

variable "execution_role_policies" {
  default     = []
  description = "AWS IAM policies that ECS might need"
  type = list(object({
    name = string
    statement = list(object({
      Action   = list(string)
      Effect   = string
      Resource = list(string)
    }))
  }))
}

variable "health_check_grace_period_in_seconds" {
  description = "Grace period to start to control health check on task definition"
  type        = number
}

variable "load_balancer_arn" {
  description = "Load balancer ARN"
  type        = string
}
variable "memory" {
  default     = 2048
  description = "The memory size in megabytes"
  type        = number
}

variable "service_name" {
  description = "The ECS service name"
  type        = string
  validation {
    condition     = can(regex("^[A-Za-z][0-9A-Za-z-]*$", var.service_name))
    error_message = "service_name must start with a letter and can only contain letters, numbers, or hyphens."
  }
  validation {
    condition     = length(var.service_name) > 0 && length(var.service_name) <= 255
    error_message = "service_name must be between 1 and 255 characters."
  }
}

variable "subnets" {
  description = "List of subnets used by the ECS service"
  type        = list(string)
}

variable "task_definition" {
  description = "Task definition configuration block"
  type = object({
    entrypoint_container_name = string
    entrypoint_container_port = number
  })
}

variable "target_group_arn" {
  description = "Target group ARN"
  type        = string
}

variable "task_role_extra_assume_role_permission" {
  default = []
  description = "Extra policy statement to attach to ecs task role"
  type = list(object({
    Sid       = optional(string, "")
    Action    = list(string)
    Effect    = string
    Principal = object({
      AWS = optional(list(string))
      Service = optional(list(string))
    })
  }))
}

variable "task_role_policies" {
  default     = []
  description = "AWS IAM policies that the application might need"
  type = list(object({
    name = string
    statement = list(object({
      Action    = list(string)
      Effect    = string
      Resource  = list(string)
    }))
  }))
}

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}
