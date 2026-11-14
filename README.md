# AWS infrastructure

Defines a VPC, two public subnets in Mumbai (`ap-south-1`), three standalone Ubuntu EC2 servers, IAM roles, an EKS cluster, and its managed worker nodes.

| Resources | Default | Access |
| --- | --- | --- |
| 3 standalone EC2 servers | Ubuntu 24.04, `t3.medium`, On-Demand, 30 GiB encrypted gp3 each | SSH as `ubuntu`, from your public IP only |
| 3 EKS workers | EKS AL2023 image, `t3.medium`, On-Demand | Kubernetes API through `kubectl`; node SSH disabled |

That is **six EC2 instances total**, plus the EKS control plane. The standalone servers are separate from Kubernetes workers. They start as clean Ubuntu machines; Jenkins and other tools are not installed yet.

## Names

`project_name` in `variables.tf` defaults to `my-project`. AWS names include:

- `my-project-vpc`
- `my-project-subnet-1` and `my-project-subnet-2`
- `my-project-cluster`
- `my-project-node-group`
- `my-project-cluster-role` and `my-project-node-group-role`
- `my-project-server-1`, `my-project-server-2`, and `my-project-server-3`
- `my-project-ssh` (EC2 key pair containing your existing public key)

VPC means Virtual Private Cloud. PVC means PersistentVolumeClaim, a Kubernetes storage resource that belongs in the deployment configuration later.

## Configure and apply

Run Terraform on your local machine from this directory, with AWS CLI credentials configured for your account:

```sh
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`: replace `203.0.113.10/32` with **your current public IPv4 address followed by `/32`**. The example address will not let you SSH. This is your internet-facing IP, not a private Wi-Fi address such as `192.168.x.x`. Update it if your ISP or VPN changes your address.

The variables control:

- `ec2_instance_type`: type for all three standalone servers, default `t3.medium`. They use On-Demand purchasing; no Spot request is configured.
- `eks_instance_types`: worker types, default `["t3.medium"]`.
- `eks_capacity_type`: default `ON_DEMAND`; `SPOT` is also supported if you deliberately change it.
- `eks_node_count`: fixed worker count, default `3`. EKS manages node lifecycle; these variables do not install a workload autoscaler.

Use x86_64-compatible instance types with the configured images; moving to ARM requires changing the images too. Capacity-type changes may replace the managed node group; inspect the plan.

Then run:

```sh
aws sts get-caller-identity
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Review the plan and confirm `apply` when ready. Terraform automatically imports `../.keys/bankapp-eks.pub` under the EC2 key name `my-project-ssh`; no manual key import is required. It never reads or uploads the private key. If that AWS key name already exists outside this state, import the existing key pair into Terraform instead of creating a duplicate.

If you clone this infrastructure repository separately, place your existing key files in a sibling `.keys/` directory: `../.keys/bankapp-eks.pub` and `../.keys/bankapp-eks`. Keep the private key outside the repository. Terraform requires the public key file; SSH requires its matching private key.

The official Ubuntu AMI is looked up by Canonical's owner ID and image name. New Ubuntu images can cause a later plan to propose server replacements; review the plan. See [Canonical's image lookup documentation](https://ubuntu.com/aws/docs/aws-how-to/instances/find-ubuntu-images/).

## SSH after creation

From this Terraform directory:

```sh
terraform output server_1
terraform output server_2
terraform output server_3
```

Each output includes its instance ID, public IP, private IP, and a ready-to-copy `ssh_command`. Run that SSH command **on your local machine**, where the private key exists. Allow a short time for Ubuntu to boot after Terraform completes.

Alternatively, replace each placeholder below with its public IP:

```sh
chmod 600 ../.keys/bankapp-eks
ssh -i ../.keys/bankapp-eks ubuntu@SERVER_1_PUBLIC_IP
ssh -i ../.keys/bankapp-eks ubuntu@SERVER_2_PUBLIC_IP
ssh -i ../.keys/bankapp-eks ubuntu@SERVER_3_PUBLIC_IP
```

Run one SSH command at a time, or use three terminal tabs. After login, commands execute on that server; use `exit` to return to your local machine. Terraform-generated SSH commands quote the full key path because this project path contains spaces.

Only port 22 is open inbound, restricted to your IP. Add service ports deliberately when installing tools later. Public IPs can change after stop/start; refresh Terraform outputs before using them again. Losing the private key means losing this SSH login, so keep it outside Git and backed up securely.

## EKS access

EKS worker SSH remains disabled and does not need the EC2 key. After applying, use the same AWS identity that created the cluster:

```sh
aws eks update-kubeconfig --region ap-south-1 --name my-project-cluster
kubectl get nodes
```

If you change `project_name`, use the actual command from `terraform output -raw kubeconfig_command`.

SSH access to an Ubuntu server does not automatically give it AWS or EKS permissions. To use it as an administration machine later, install AWS CLI / kubectl there and configure a suitable IAM role and EKS access. See [AWS kubectl authentication](https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html).

AWS resources incur charges. This is still a public-subnet lab setup. Before deployment, select a supported EKS Kubernetes version, configure subnet discovery for your chosen load balancer controller, and validate the AWS plan. Keep `.terraform.lock.hcl` in Git; keep `.terraform/`, state, `terraform.tfvars`, and private keys out of Git.

Resource addresses and AWS names were renamed before any local state was found. If you have already applied the old configuration from another machine or backend, stop and plan a state migration before applying these renames; changing names may replace resources.
