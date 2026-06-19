locals {
  name = "petclinic-${var.environment}"
  subnet_cidrs = [
    cidrsubnet(var.vpc_cidr, 8, 0),
    cidrsubnet(var.vpc_cidr, 8, 1),
  ]
  tags = merge(
    {
      Project     = "petclinic"
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.tags,
    {
      Name = "${local.name}-vpc"
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.tags,
    {
      Name = "${local.name}-igw"
    }
  )
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.tags,
    {
      Name                                                 = "${local.name}-public-${var.availability_zones[count.index]}"
      "kubernetes.io/cluster/petclinic-${var.environment}" = "shared"
      "kubernetes.io/role/elb"                             = "1"
    }
  )
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.tags,
    {
      Name = "${local.name}-public-rt"
    }
  )
}

# Route to Internet Gateway
resource "aws_route" "internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# EKS Cluster Security Group
resource "aws_security_group" "eks_cluster" {
  name_prefix = "${local.name}-eks-cluster-"
  description = "Security group for EKS cluster control plane"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    local.tags,
    {
      Name = "${local.name}-eks-cluster-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "eks_cluster_nodes" {
  description                  = "Allow nodes to communicate with cluster"
  security_group_id            = aws_security_group.eks_cluster.id
  referenced_security_group_id = aws_security_group.eks_node.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "eks_cluster_outbound" {
  description       = "Allow outbound traffic from cluster"
  security_group_id = aws_security_group.eks_cluster.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# EKS Node Security Group
resource "aws_security_group" "eks_node" {
  name_prefix = "${local.name}-eks-node-"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    local.tags,
    {
      Name                                                 = "${local.name}-eks-node-sg"
      "kubernetes.io/cluster/petclinic-${var.environment}" = "owned"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "eks_node_self" {
  description                  = "Allow nodes to communicate with each other"
  security_group_id            = aws_security_group.eks_node.id
  referenced_security_group_id = aws_security_group.eks_node.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "eks_node_cluster" {
  description                  = "Allow cluster to communicate with nodes"
  security_group_id            = aws_security_group.eks_node.id
  referenced_security_group_id = aws_security_group.eks_cluster.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_egress_rule" "eks_node_outbound" {
  description       = "Allow outbound traffic from nodes"
  security_group_id = aws_security_group.eks_node.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# RDS Security Group
resource "aws_security_group" "rds" {
  name_prefix = "${local.name}-rds-"
  description = "Security group for RDS database"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    local.tags,
    {
      Name = "${local.name}-rds-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_eks_nodes" {
  description                  = "Allow EKS nodes to connect to RDS"
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.eks_node.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
}

# ALB Security Group
resource "aws_security_group" "alb" {
  name_prefix = "${local.name}-alb-"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    local.tags,
    {
      Name = "${local.name}-alb-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  description       = "Allow HTTP traffic"
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  description       = "Allow HTTPS traffic"
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_outbound" {
  description                  = "Allow outbound traffic to EKS nodes"
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.eks_node.id
  ip_protocol                  = "-1"
}
