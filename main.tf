provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "my_project_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "my_project_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.my_project_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.my_project_vpc.cidr_block, 8, count.index)
  availability_zone       = element(["ap-south-1a", "ap-south-1b"], count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "my_project_igw" {
  vpc_id = aws_vpc.my_project_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_route_table" "my_project_route_table" {
  vpc_id = aws_vpc.my_project_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_project_igw.id
  }

  tags = {
    Name = "${var.project_name}-route-table"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.my_project_subnet[count.index].id
  route_table_id = aws_route_table.my_project_route_table.id
}

resource "aws_security_group" "my_project_cluster_sg" {
  vpc_id = aws_vpc.my_project_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-cluster-sg"
  }
}

resource "aws_eks_cluster" "my_project" {
  name     = "${var.project_name}-cluster"
  role_arn = aws_iam_role.my_project_cluster_role.arn

  vpc_config {
    subnet_ids         = aws_subnet.my_project_subnet[*].id
    security_group_ids = [aws_security_group.my_project_cluster_sg.id]
  }

  depends_on = [aws_iam_role_policy_attachment.my_project_cluster_role_policy]
}

resource "aws_eks_node_group" "my_project" {
  cluster_name    = aws_eks_cluster.my_project.name
  node_group_name = "${var.project_name}-node-group"
  node_role_arn   = aws_iam_role.my_project_node_group_role.arn
  subnet_ids      = aws_subnet.my_project_subnet[*].id

  scaling_config {
    desired_size = var.eks_node_count
    max_size     = var.eks_node_count
    min_size     = var.eks_node_count
  }

  instance_types = var.eks_instance_types
  capacity_type  = var.eks_capacity_type
  ami_type       = "AL2023_x86_64_STANDARD"

  # Nodes do not need SSH access for normal Kubernetes operations.
  depends_on = [
    aws_iam_role_policy_attachment.my_project_node_group_role_policy,
    aws_iam_role_policy_attachment.my_project_node_group_cni_policy,
    aws_iam_role_policy_attachment.my_project_node_group_registry_policy,
    aws_route_table_association.public,
  ]
}

resource "aws_iam_role" "my_project_cluster_role" {
  name = "${var.project_name}-cluster-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "my_project_cluster_role_policy" {
  role       = aws_iam_role.my_project_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "my_project_node_group_role" {
  name = "${var.project_name}-node-group-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "my_project_node_group_role_policy" {
  role       = aws_iam_role.my_project_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "my_project_node_group_cni_policy" {
  role       = aws_iam_role.my_project_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "my_project_node_group_registry_policy" {
  role       = aws_iam_role.my_project_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
