output "cluster_arn" {
  value = aws_ecs_service.service.cluster
}

output "security_group_id" {
  description = "The application security group id"
  value       = aws_security_group.security_group.id
}

output "service_arn" {
  description = "Service ARN"
  value       = aws_ecs_service.service.id
}

output "service_name" {
  description = "Service name"
  value       = aws_ecs_service.service.name
}

output "scalable_target_namespace" {
  description = "The scalable target namespace"
  value       = aws_appautoscaling_target.ecs_target.service_namespace
}

output "scalable_target_dimension" {
  description = "The scalable target dimension"
  value       = aws_appautoscaling_target.ecs_target.scalable_dimension
}

output "scalable_target_id" {
  description = "The scalable target id"
  value       = aws_appautoscaling_target.ecs_target.resource_id
}
