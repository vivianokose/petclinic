output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "eks_cluster_sg_id" {
  description = "Security group ID for the EKS cluster control plane"
  value       = module.vpc.eks_cluster_sg_id
}

output "eks_node_sg_id" {
  description = "Security group ID for EKS worker nodes"
  value       = module.vpc.eks_node_sg_id
}

output "rds_sg_id" {
  description = "Security group ID for RDS database"
  value       = module.vpc.rds_sg_id
}

output "alb_sg_id" {
  description = "Security group ID for the Application Load Balancer"
  value       = module.vpc.alb_sg_id
}

# EKS outputs
output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint URL for the EKS cluster API server"
  value       = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "Base64-encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_ca_certificate
  sensitive   = true
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC provider for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "The URL of the OIDC provider for IRSA"
  value       = module.eks.oidc_provider_url
}

output "node_group_name" {
  description = "The name of the EKS managed node group"
  value       = module.eks.node_group_name
}

output "node_role_arn" {
  description = "The ARN of the IAM role assigned to the worker nodes"
  value       = module.eks.node_role_arn
}
