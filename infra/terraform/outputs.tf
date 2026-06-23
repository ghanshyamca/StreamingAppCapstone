output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID created for the platform"
}

output "private_subnets" {
  value       = module.vpc.private_subnets
  description = "Private subnet IDs used by EKS"
}

output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "Name of the EKS cluster"
}

output "eks_cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "API endpoint for the EKS cluster"
}

output "ecr_repository_urls" {
  value = {
    for name, repository in aws_ecr_repository.services : name => repository.repository_url
  }
  description = "Repository URLs for application images"
}

output "terraform_state_bucket" {
  value       = aws_s3_bucket.terraform_state.bucket
  description = "S3 bucket holding Terraform state"
}

output "terraform_lock_table" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "DynamoDB table used for Terraform locking"
}

output "jenkins_security_group_id" {
  value       = aws_security_group.jenkins.id
  description = "Security group for the Jenkins host"
}