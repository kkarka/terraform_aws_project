# Terraform on AWS – End-to-End Infrastructure Deployment

## Project Overview

In this project, I designed and provisioned a **highly available web infrastructure on AWS using Terraform**.

Instead of manually creating resources in the AWS Console, I defined the entire infrastructure as code using Terraform. This approach ensures:

- Repeatability  
- Consistency  
- Scalability  
- Version control  
- Automated provisioning  

---

## Architecture

### High-Level Design


Internet
│
▼
Application Load Balancer
│
▼
Target Group
│
├── EC2 Instance 1 (AZ-1)
└── EC2 Instance 2 (AZ-2)


### Components Provisioned

- Custom VPC  
- Two Public Subnets (Multi-AZ)  
- Internet Gateway  
- Route Table & Associations  
- Security Group (HTTP + SSH)  
- Two EC2 Web Servers (Apache via user_data)  
- Application Load Balancer  
- Target Group with Health Checks  

---

## What I Implemented

### 1. Custom VPC

- Created a VPC with configurable CIDR block
- Avoided default VPC (production-style design)
- Tagged resources for cost tracking

---

### 2. Multi-AZ Public Subnets

- Two public subnets in different Availability Zones
- Auto-assign public IP enabled
- Designed for high availability

---

### 3. Internet Gateway & Routing

- Attached Internet Gateway to VPC
- Created route table
- Routed `0.0.0.0/0` to IGW
- Associated route table with both public subnets

---

### 4. Security Group

Configured:

- HTTP (Port 80) – Open to public  
- SSH (Port 22) – Open (demo purpose only)  
- All outbound traffic allowed  

> ⚠ In production, SSH should be restricted or replaced with SSM Session Manager.

---

### 5. EC2 Web Servers

- Ubuntu AMI  
- `t2.micro` (Free tier eligible)  
- Apache installed via `user_data`  
- Displays dynamic Instance ID  

This demonstrates automated instance bootstrapping.

---

### 6. Application Load Balancer

- Internet-facing
- Deployed across two public subnets
- HTTP Listener on port 80
- Forwards traffic to target group

---

### 7. Target Group & Health Checks

- Registers both EC2 instances
- Health check configured on `/`
- Routes traffic only to healthy instances

---

## Technologies Used

- Terraform (AWS Provider ~> 6.x)
- AWS CLI
- Amazon EC2
- Amazon VPC
- Application Load Balancer
- Security Groups

---

## Project Structure


terraform-aws-project/
│
├── provider.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── user_data.sh
├── user_data_2.sh
├── .gitignore
└── README.md


---

# How to Execute This Project

## Step 1: Prerequisites

Make sure you have:

- An active AWS account
- Terraform installed
- AWS CLI installed

---

## Step 2: Configure AWS Credentials

Use an IAM user (not root).

```bash
aws configure
```
Provide:
- AWS Access Key
- AWS Secret Access Key
- Region (e.g., ap-south-1)
- Output format (optional)

Terraform will use these credentials automatically.


## Step 3: Initialize Terraform
```bash
terraform init
```
This downloads required providers and initializes the project.


## Step 4: Validate Configuration
```bash
terraform validate
```
Ensures syntax correctness.


## Step 5: Review Execution Plan
```bash
terraform plan
```
This shows:
- Resources to be created
- Dependencies
- Any changes Terraform will perform

Always review before applying.


## Step 6: Deploy Infrastructure
```bash
terraform apply
```
Type:
```bash
yes
```
Terraform provisions:
- VPC
- Subnets
- Internet Gateway
- Route Tables
- Security Group
- EC2 Instances
- Load Balancer
- Target Group
- Listener

---
## Access the Application

After successful deployment:

Terraform outputs the Load Balancer DNS name.

Copy the DNS name into your browser.

You should see alternating responses from both EC2 servers.
---

## Clean Up (Important)

To avoid AWS charges:
```bash
terraform destroy
```
Confirm with:
```bash
yes
```
This deletes all created resources.

---
## Best Practices Followed
- Used IAM user instead of root
- Did not hardcode credentials
- Added .terraform/ and *.tfstate* to .gitignore
- Used provider version constraints
- Tagged resources
- Followed idempotent Infrastructure-as-Code design
---

## Cost Considerations
Resources that may incur cost:
- Application Load Balancer
- EC2 (if outside free tier)
- Data transfer

Always run:
```bash
terraform destroy
```
after testing.

---

## Future Improvements
- Remote backend (S3 + DynamoDB locking)
- Auto Scaling Group
- HTTPS with ACM
- Route53 custom domain
- Private subnets + NAT Gateway
- CI/CD integration
- Modular Terraform structure

---

## What This Project Demonstrates

Through this project, I demonstrated:
- AWS networking fundamentals
- Infrastructure as Code expertise
- High availability architecture
- Load balancing configuration
- Resource dependency management
- Cost awareness and cleanup discipline

## Author
Kiran Kumar Arka
DevOps | Cloud | Terraform | AWS

