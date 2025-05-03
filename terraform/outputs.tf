output "cluster_name" {
  value       = aws_eks_cluster.eks.name
  description = "The name of the EKS cluster"
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.eks.endpoint
  description = "The endpoint for the EKS cluster API server"
}

output "cluster_security_group_id" {
  value       = aws_security_group.eks_cluster.id
  description = "Security group ID for the EKS cluster"
}

output "node_group_name" {
  value       = aws_eks_node_group.node_group.node_group_name
  description = "The name of the EKS node group"
}

output "node_group_status" {
  value       = aws_eks_node_group.node_group.status
  description = "Status of the EKS node group"
}

output "kubectl_config_command" {
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.eks.name}"
  description = "Command to configure kubectl for this EKS cluster"
}

output "vpc_id" {
  value       = aws_vpc.eks_vpc.id
  description = "The ID of the VPC"
}