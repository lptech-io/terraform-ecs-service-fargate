<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.49 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.49 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_appautoscaling_policy.ecs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_target.ecs_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_ecs_service.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.task_definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_role.execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_security_group.security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.permit_outbound_traffic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_autoscaling_configuration"></a> [autoscaling\_configuration](#input\_autoscaling\_configuration) | Autoscaling configuration for ECS service | <pre>object({<br>    max_connections_per_container = optional(number, 500)<br>    max_capacity                  = number<br>    min_capacity                  = number<br>  })</pre> | n/a | yes |
| <a name="input_cluster_arn"></a> [cluster\_arn](#input\_cluster\_arn) | The ECS cluster ARN | `string` | n/a | yes |
| <a name="input_container_definitions"></a> [container\_definitions](#input\_container\_definitions) | Container definitions for the ECS service | <pre>list(object({<br>    name   = string<br>    image  = string<br>    cpu    = optional(number)<br>    memory = optional(number)<br>    portMappings = optional(list(object({<br>      hostPort      = optional(number)<br>      containerPort = number<br>      protocol      = string<br>    })))<br>    essential  = optional(bool)<br>    entryPoint = optional(list(string))<br>    command    = optional(list(string))<br>    firelensConfiguration = optional(object({<br>      type = string<br>      options = object({<br>        config-file-type        = string<br>        enable-ecs-log-metadata = string<br>        config-file-value       = string<br>      })<br>    }))<br>    logConfiguration = optional(object({<br>      logDriver = string<br>      options   = optional(map(string))<br>    }))<br>    environment = optional(list(object({<br>      name  = string<br>      value = string<br>    })))<br>    secrets = optional(list(object({<br>      name      = string<br>      valueFrom = string<br>    })))<br>  }))</pre> | n/a | yes |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | The CPU units | `number` | `1024` | no |
| <a name="input_ecr_repository_arns"></a> [ecr\_repository\_arns](#input\_ecr\_repository\_arns) | The ECR repository ARNs | `list(string)` | `[]` | no |
| <a name="input_execution_role_policies"></a> [execution\_role\_policies](#input\_execution\_role\_policies) | AWS IAM policies that ECS might need | <pre>list(object({<br>    name = string<br>    statement = list(object({<br>      Action   = list(string)<br>      Effect   = string<br>      Resource = list(string)<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_health_check_grace_period_in_seconds"></a> [health\_check\_grace\_period\_in\_seconds](#input\_health\_check\_grace\_period\_in\_seconds) | Grace period to start to control health check on task definition | `number` | n/a | yes |
| <a name="input_load_balancer_arn"></a> [load\_balancer\_arn](#input\_load\_balancer\_arn) | Load balancer ARN | `string` | n/a | yes |
| <a name="input_memory"></a> [memory](#input\_memory) | The memory size in megabytes | `number` | `2048` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | The ECS service name | `string` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | List of subnets used by the ECS service | `list(string)` | n/a | yes |
| <a name="input_target_group_arn"></a> [target\_group\_arn](#input\_target\_group\_arn) | Target group ARN | `string` | n/a | yes |
| <a name="input_task_definition"></a> [task\_definition](#input\_task\_definition) | Task definition configuration block | <pre>object({<br>    entrypoint_container_name = string<br>    entrypoint_container_port = number<br>  })</pre> | n/a | yes |
| <a name="input_task_role_extra_allowed_principals"></a> [task\_role\_extra\_allowed\_principals](#input\_task\_role\_extra\_allowed\_principals) | Extra allowed principals for ECS task role | <pre>object({<br>    aws = optional(list(string))<br>    service = optional(list(string))<br>  })</pre> | <pre>{<br>  "aws": [],<br>  "service": []<br>}</pre> | no |
| <a name="input_task_role_policies"></a> [task\_role\_policies](#input\_task\_role\_policies) | AWS IAM policies that the application might need | <pre>list(object({<br>    name = string<br>    statement = list(object({<br>      Action    = list(string)<br>      Effect    = string<br>      Resource  = list(string)<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC ID | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | n/a |
| <a name="output_scalable_target_dimension"></a> [scalable\_target\_dimension](#output\_scalable\_target\_dimension) | The scalable target dimension |
| <a name="output_scalable_target_id"></a> [scalable\_target\_id](#output\_scalable\_target\_id) | The scalable target id |
| <a name="output_scalable_target_namespace"></a> [scalable\_target\_namespace](#output\_scalable\_target\_namespace) | The scalable target namespace |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | The application security group id |
| <a name="output_service_arn"></a> [service\_arn](#output\_service\_arn) | Service ARN |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | Service name |
<!-- END_TF_DOCS -->