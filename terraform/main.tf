provider "aws" {
  region = var.region
}

# VPC with DNS support
resource "aws_vpc" "eks_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-vpc"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
  )
}

# Internet Gateway - required for nodes to reach internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eks_vpc.id
  
  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-igw"
    }
  )
}

# Public subnets with the required EKS tags
resource "aws_subnet" "subnet_a" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.subnet_cidrs["a"]
  availability_zone       = var.availability_zones["a"]
  map_public_ip_on_launch = true
  
  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-subnet-a"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      "kubernetes.io/role/elb" = "1"
    }
  )
}

resource "aws_subnet" "subnet_b" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.subnet_cidrs["b"]
  availability_zone       = var.availability_zones["b"]
  map_public_ip_on_launch = true
  
  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-subnet-b"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      "kubernetes.io/role/elb" = "1"
    }
  )
}

# Route table for internet access
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.eks_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-public-route-table"
    }
  )
}

# Associate route table with subnets
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.public.id
}

# EKS Cluster IAM Role
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
  
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# EKS Cluster
resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  
  vpc_config {
    subnet_ids              = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }
  
  # Ensure the IAM role permissions are created before the cluster
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
    aws_internet_gateway.igw
  ]
  
  # Add timeout for cluster creation
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
  
  tags = var.tags
}

# Security group for EKS cluster
resource "aws_security_group" "eks_cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.eks_vpc.id
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-cluster-sg"
    }
  )
}

# Node group IAM role
resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-node-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
  
  tags = var.tags
}

# Node group IAM policies
resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

# Security group for nodes
resource "aws_security_group" "eks_nodes" {
  name        = "${var.cluster_name}-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.eks_vpc.id
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-node-sg"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )
}

# Allow communication between nodes and cluster
resource "aws_security_group_rule" "nodes_to_cluster" {
  description              = "Allow nodes to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster_to_nodes" {
  description              = "Allow cluster to communicate with nodes"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
  to_port                  = 65535
  type                     = "ingress"
}

# Allow nodes to communicate with each other
resource "aws_security_group_rule" "nodes_internal" {
  description              = "Allow nodes to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_nodes.id
  to_port                  = 65535
  type                     = "ingress"
}

# EKS Node Group
resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
  
  # Use instance types from variables
  instance_types = var.node_instance_types
  
  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }
  
  # Add disk size for node instances
  disk_size = var.node_disk_size
  
  # Add timeouts for node group operations
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
  
  # Ensure the IAM role permissions are created before the node group
  depends_on = [
    aws_iam_role_policy_attachment.eks_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.eks_node_AmazonEKS_CNI_Policy,
  ]
  
  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-${var.node_group_name}"
    }
  )
}