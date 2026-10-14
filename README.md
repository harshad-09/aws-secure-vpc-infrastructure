# AWS Production VPC Architecture

![AWS Production VPC Architecture](docs/architecture.png)

A highly available, secure and scalable AWS VPC setup deployed in the **Asia Pacific (Mumbai) – `ap-south-1`** region and provisioned with **Terraform**. A Flask application runs on EC2 instances in private subnets, fronted by an internet-facing Application Load Balancer, with administrative access through a bastion host.

---

## Architecture Overview

| Component | Details |
|---|---|
| **VPC** | `10.0.0.0/16` (`Vpc-Project`) |
| **Availability Zones** | `ap-south-1a`, `ap-south-1b` |
| **Public Subnets** | `10.0.1.0/24` (AZ-A), `10.0.2.0/24` (AZ-B) |
| **Private Subnets** | `10.0.11.0/24` (AZ-A), `10.0.12.0/24` (AZ-B) |
| **Internet Gateway** | `Vpc-Project-igw` – public internet access for the VPC |
| **NAT Gateways** | One per AZ (with Elastic IP) for outbound internet from private subnets |
| **Route Tables** | One public route table (→ IGW) and one private route table per AZ (→ NAT in the same AZ) |
| **Application Load Balancer** | `Vpc-Project-alb` – internet-facing, HTTP:80 |
| **Target Group** | `Vpc-Project-tg` – forwards to instances on port 8000 |
| **Auto Scaling Group** | `Vpc-Project-asg` – desired 2, min 2, max 4 |
| **EC2 Instances** | `t3.micro`, running in private subnets |
| **Bastion Host** | `bastion-host` in a public subnet (SSH access for admins) |

### Traffic Flow

1. A client sends an HTTP request to the ALB DNS name via the **Internet Gateway**.
2. The **ALB** (in public subnets) forwards the request to the **Target Group**.
3. The Target Group routes traffic to a healthy **EC2 instance in a private subnet** (port 8000).
4. Instances reach the internet for updates/packages through the **NAT Gateway** (outbound only).
5. Admins SSH to the **bastion host**, then hop to private instances.

### Key Benefits

- High availability with Multi-AZ
- Secure private subnet architecture
- Scalable with Auto Scaling
- Controlled access with bastion host
- Outbound internet via NAT Gateway (one per AZ, no single point of failure)

---

## Project Structure

```
aws-secure-vpc-infrastructure/
├── docs/                    # Architecture diagram & screenshots
├── modules/                 # Reusable Terraform modules
├── scripts/                 # Helper / user-data scripts
├── main.tf                  # Root module – wires everything together
├── variables.tf             # Input variables
├── outputs.tf               # Output values (e.g. ALB DNS name)
├── providers.tf             # AWS provider configuration
├── terraform.tfvars.example # Sample variable values
├── .terraform.lock.hcl      # Provider version lock file
├── .gitignore
└── README.md
```

---

## Prerequisites

- An AWS account with permissions to create VPC, EC2, ELB and Auto Scaling resources
- [Terraform](https://developer.hashicorp.com/terraform/downloads) installed
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured (`aws configure`)
- An existing EC2 key pair in `ap-south-1` for SSH access to the bastion host

---

## How to Deploy

```bash
# 1. Clone the repository
git clone https://github.com/harshad-09/aws-secure-vpc-infrastructure.git
cd aws-secure-vpc-infrastructure

# 2. Create your variable file from the example and edit the values
cp terraform.tfvars.example terraform.tfvars

# 3. Initialise, review and apply
terraform init
terraform plan
terraform apply
```

After `apply` finishes, Terraform prints the outputs defined in `outputs.tf`. Open the ALB DNS name in your browser to see the running application.

---

## Deployment Screenshots

### 1. VPC Architecture
The overall design of the network (shown at the top of this README).

![VPC Architecture](docs/architecture.png)

### 2. VPC Resource Map
`Vpc-Project` (`10.0.0.0/16`) with 4 subnets across two AZs, 4 route tables, and 3 network connections: the internet gateway and one NAT gateway per AZ.

![VPC Resource Map](docs/vpc-resource-map.png)

### 3. Subnets
Public subnets `10.0.1.0/24` and `10.0.2.0/24`, and private subnets `10.0.11.0/24` and `10.0.12.0/24`, all in the `Available` state.

![Subnets](docs/subnets.png)

### 4. EC2 Instances
Three instances are running with all status checks passed: two application instances spread across `ap-south-1a` and `ap-south-1b` (launched by the ASG, no public IP) and the `bastion-host` with a public IPv4 DNS.

![EC2 Instances](docs/ec2-instances.png)

### 5. Application Load Balancer
`Vpc-Project-alb` is **Active**, internet-facing, spanning two Availability Zones, with an HTTP:80 listener forwarding 100% of traffic to the `Vpc-Project-tg` target group.

![Application Load Balancer](docs/alb.png)

### 6. Load Balancer Resource Map
The listener, rule, target group and both targets (port 8000) are all connected, and both targets are **Healthy**.

![ALB Resource Map](docs/alb-resource-map.png)

### 7. Target Group
`Vpc-Project-tg` (HTTP:8000) has 2 registered targets in `ap-south-1a` and `ap-south-1b`: 2 healthy, 0 unhealthy.

![Target Group](docs/target-group.png)

### 8. Auto Scaling Group
`Vpc-Project-asg` is **At desired capacity** (desired: 2, scaling limits: 2–4) and uses a launch template with a `t3.micro` instance type.

![Auto Scaling Group](docs/asg.png)

### 9. Running Application
The application is reachable through the ALB DNS name. The page confirms the request was served from a **private subnet** (`10.0.11.52`, port 8000) after passing through the Internet Gateway and Load Balancer, and the `/health` endpoint returns `200`.

![Running Application](docs/running-app.png)

---

## Verify It Yourself

```bash
# Hit the load balancer
curl http://<alb-dns-name>

# Health check endpoint used by the target group
curl http://<alb-dns-name>/health
```

Replace `<alb-dns-name>` with the DNS name shown on the load balancer details page (e.g. `Vpc-Project-alb-xxxxxxxxxx.ap-south-1.elb.amazonaws.com`).

---

## Access Private Instances via Bastion Host

```bash
# Use SSH agent forwarding so the key never has to be copied to the bastion
ssh-add <your-key>.pem
ssh -A ubuntu@<bastion-public-ip>

# From the bastion, connect to a private instance
ssh ubuntu@<private-instance-ip>
```

The default SSH user depends on the AMI (`ubuntu` for Ubuntu, `ec2-user` for Amazon Linux).

## Security Notes

- Application instances have **no public IP** and are only reachable through the ALB.
- Security groups allow app traffic only from the ALB, and SSH only from the bastion host.
- Restrict the bastion host's SSH rule to **your own IP** instead of `0.0.0.0/0`.
- The ALB listener is HTTP only (demo setup). For production, add an HTTPS listener with an ACM certificate and redirect HTTP to HTTPS.
- Never commit `terraform.tfvars`, `*.pem` files or state files – keep them in `.gitignore`.

## Cleanup

NAT Gateways and the load balancer are billed hourly, so destroy the stack when you are done testing:

```bash
terraform destroy
```

## AWS Services Used

Amazon VPC · Amazon EC2 · Application Load Balancer · Target Groups · Auto Scaling Group · NAT Gateway · Internet Gateway · Bastion Host · Security Groups · Terraform