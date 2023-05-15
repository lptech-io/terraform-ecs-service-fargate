terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.49" # Added alarm section on aws_ecs_service and in the 4.47 added some bugfixes
    }
  }
}
