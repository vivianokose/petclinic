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
