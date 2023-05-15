locals {
  load_balancer_id = replace(var.load_balancer_arn, "/.*:/", "")
  target_group_id  = replace(var.target_group_arn, "/.*:/", "")
}
