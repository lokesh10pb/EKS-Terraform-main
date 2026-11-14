output "cluster_id" {
  value = aws_eks_cluster.my_project.id
}

output "kubeconfig_command" {
  description = "Run locally after applying to configure kubectl; use the AWS identity that created the cluster"
  value       = "aws eks update-kubeconfig --region ap-south-1 --name ${aws_eks_cluster.my_project.name}"
}

output "node_group_id" {
  value = aws_eks_node_group.my_project.id
}

output "vpc_id" {
  value = aws_vpc.my_project_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.my_project_subnet[*].id
}

output "server_1" {
  description = "Standalone Ubuntu server 1 and its SSH command (run on your local machine)"
  value = {
    instance_id = aws_instance.servers[0].id
    public_ip   = aws_instance.servers[0].public_ip
    private_ip  = aws_instance.servers[0].private_ip
    ssh_command = "ssh -i '${abspath("${path.module}/../.keys/bankapp-eks")}' ubuntu@${aws_instance.servers[0].public_ip}"
  }
}

output "server_2" {
  description = "Standalone Ubuntu server 2 and its SSH command (run on your local machine)"
  value = {
    instance_id = aws_instance.servers[1].id
    public_ip   = aws_instance.servers[1].public_ip
    private_ip  = aws_instance.servers[1].private_ip
    ssh_command = "ssh -i '${abspath("${path.module}/../.keys/bankapp-eks")}' ubuntu@${aws_instance.servers[1].public_ip}"
  }
}

output "server_3" {
  description = "Standalone Ubuntu server 3 and its SSH command (run on your local machine)"
  value = {
    instance_id = aws_instance.servers[2].id
    public_ip   = aws_instance.servers[2].public_ip
    private_ip  = aws_instance.servers[2].private_ip
    ssh_command = "ssh -i '${abspath("${path.module}/../.keys/bankapp-eks")}' ubuntu@${aws_instance.servers[2].public_ip}"
  }
}
