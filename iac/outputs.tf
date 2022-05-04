# Output Variable Definitions

output "vpc_id" {
  description = "ID of the provisioned VPC"
  value       = module.vpc.vpc_id
}

output "vpc_public_subnets" {
  description = "IDs of public subnets in the VPC"
  value       = module.vpc.public_subnets
}

output "repository_url" {
  description = "The URL of the repository"
  value       = module.ecr.repository_url
}

output "aws_iam_user_arn" {
  description = "ARN value of current AWS IAM User"
  value       = data.aws_iam_user.current.arn
}

output "aws_lb_dns_name" {
  description = "LoadBalancer DNS Name of ECS Cluster"
  value       = aws_lb.ecs.dns_name
}