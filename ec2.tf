# Official Canonical Ubuntu 24.04 LTS image for the selected AWS region.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Import only the existing public key. The private key stays on your machine.
resource "aws_key_pair" "servers" {
  key_name   = "${var.project_name}-ssh"
  public_key = file("${path.module}/../.keys/bankapp-eks.pub")
}

resource "aws_security_group" "servers" {
  name        = "${var.project_name}-servers-sg"
  description = "SSH to standalone servers from your public IP"
  vpc_id      = aws_vpc.my_project_vpc.id

  ingress {
    description = "SSH from your machine"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-servers-sg"
  }
}

resource "aws_instance" "servers" {
  count = 3

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.ec2_instance_type
  subnet_id                   = aws_subnet.my_project_subnet[count.index % length(aws_subnet.my_project_subnet)].id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.servers.id]
  key_name                    = aws_key_pair.servers.key_name

  # No Spot market options: these are On-Demand EC2 instances.
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "${var.project_name}-server-${count.index + 1}"
  }

  depends_on = [aws_route_table_association.public]
}
