provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "eks-vpc-bloggingapp"
  }
}

resource "aws_subnet" "eks_subnet" {
  count = 2
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.eks_vpc.cidr_block, 8, count.index)
  availability_zone       = element(["ap-southeast-1a", "ap-southeast-1b"], count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "eks-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "eks-igw"
  }
}

resource "aws_route_table" "eks_route_table" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }

  tags = {
    Name = "eks-route-table"
  }
}

resource "aws_route_table_association" "eks_route_table_association" {
  count          = 2
  subnet_id      = aws_subnet.eks_subnet[count.index].id
  route_table_id = aws_route_table.eks_route_table.id
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = "bloggingapp"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids         = aws_subnet.eks_subnet[*].id
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "blogging-node-group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = aws_subnet.eks_subnet[*].id

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  instance_types = ["t2.medium"]

  remote_access {
    ec2_ssh_key = "devops"
    source_security_group_ids = [aws_security_group.eks_node_sg.id]
  }
}

