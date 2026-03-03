# Creating a Custom VPC (Virtual Private Cloud)
resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr # Defines the IP address range for the VPC

  tags = {
    Name = "MyTerraformVPC" # Assigns a name tag to the VPC for identification
  }
}


#Creating Public Subnets within the VPC
resource "aws_subnet" "public_subnet1" {
  vpc_id     = aws_vpc.myvpc.id # Associates the subnet with the VPC created above
  cidr_block = "10.0.1.0/24" # Defines the IP address range for the subnet
  availability_zone = "ap-south-1a" # Specifies the availability zone for the subnet
  map_public_ip_on_launch = true # Automatically assigns public IPs to instances launched in this subnet
}

resource "aws_subnet" "public_subnet2" {
  vpc_id = aws_vpc.myvpc.id # Associates the subnet with the VPC created above
  cidr_block = "10.0.2.0/24" # Defines the IP address range for the subnet
  availability_zone = "ap-south-1b" # Specifies the availability zone for the subnet 
  map_public_ip_on_launch = true # Automatically assigns public IPs to instances launched in this subnet
}



# Creating an Internet Gateway and associating it with the VPC
resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id 
}


# Creating a Public Route Table and Route to the Internet Gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.myvpc.id 

  route {
    cidr_block = "0.0.0.0/0" # Destination for all internet traffic
    gateway_id = aws_internet_gateway.myigw.id #Route through the Internet Gateway
  }
}


# Associating Subnets with the Public Route Table  
resource "aws_route_table_association" "public_subnet1_assoc" {
  subnet_id      = aws_subnet.public_subnet1.id # Associates the route table with the first public subnet
  route_table_id = aws_route_table.public_rt.id # Specifies the route table to associate
}

resource "aws_route_table_association" "public_subnet2_assoc" {
  subnet_id      = aws_subnet.public_subnet2.id # Associates the route table with the second public subnet
  route_table_id = aws_route_table.public_rt.id # Specifies the route table to associate
}


# Creating a Security Group to allow HTTP and SSH access to the EC2 instances
resource "aws_security_group" "web_server_sg" {
  name = "web-server-access" # Name of the security group
  description = "Allow HTTP and SSH inbound traffic to web servers" # Description of the security group
  vpc_id = aws_vpc.myvpc.id

  # Inbound rule for HTTP (Port 80) from anywhere
  ingress {
    from_port = 80 # Allow HTTP traffic on port 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic from any IP address
  }

  # Inbound rule for SSH (Port 22) from anywhere - Note: In production, it's recommended to restrict this to specific IPs for security reasons
  ingress {
    from_port = 22 # Allow SSH traffic on port 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic from any IP address
  }

  # Outbound rule to allow all outbound traffic
  egress { 
    from_port = 0 # Allow all outbound traffic
    to_port = 0
    protocol = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic from any IP address
  }
}   


# Creating an S3 Bucket
resource "aws_s3_bucket" "mybucket" {
  bucket = "arka-tf-bucket-1" # Unique name for the S3 bucket
}


# Creating EC2 Instances
resource "aws_instance" "web_server_1" {
  ami = "ami-019715e0d74f695be" # Ubuntu AMI ID for the ap-south-1 region
  instance_type = "t2.micro" # Instance type for the EC2 instance
  vpc_security_group_ids = [aws_security_group.web_server_sg.id] # Associate the security group with the instance
  subnet_id = aws_subnet.public_subnet1.id # Launch the instance in the first public subnet
  user_data = base64encode(file("user_data.sh")) # Provide the user data script to configure the instance on launch 
}

resource "aws_instance" "web_server_2" {
  ami = "ami-019715e0d74f695be" # Ubuntu AMI ID for the ap-south-1 region
  instance_type = "t2.micro" # Instance type for the EC2 instance
  vpc_security_group_ids = [aws_security_group.web_server_sg.id] # Associate the security group with the instance
  subnet_id = aws_subnet.public_subnet2.id # Launch the instance in the second public subnet
  user_data = base64encode(file("user_data_2.sh")) # Provide the user data script to configure the instance on launch 
}


# Creating an Application Load Balancer (ALB)
resource "aws_lb" "web_app_lb" {
  name               = "my-web-app-lb" # Name of the load balancer
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_server_sg.id] # Associate the security group with the load balancer
  subnets            = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id] # Place the load balancer in both public subnets for high availability  

  tags = {
    Environment = "WebAppALB" # Tag for identifying the load balancer
  }
}


# Creating a Target Group for the ALB
resource "aws_lb_target_group" "web_app_tg" {
  name = "my-web-app-tg" # Name of the target group
  port = 80 # Port on which the target group will receive traffic
  protocol = "HTTP" # Protocol for the target group
  vpc_id = aws_vpc.myvpc.id # Associate the target group with the VPC

  #Health check configuration for the target group
  health_check {
    path = "/"
    port = "traffic-port" # Use the port the target group is listening on
    protocol = "HTTP" 
    interval = 30 # Time between health checks
    timeout = 5 # Time to wait for a response before marking the target as unhealthy
    healthy_threshold = 2 # Number of consecutive successful health checks before marking the target as healthy
    unhealthy_threshold = 2 # Number of consecutive failed health checks before marking the target as unhealthy
  }
}


# Attaching EC2 Instances to the Target Group
resource "aws_lb_target_group_attachment" "web_server_1_attachment" {
  target_group_arn = aws_lb_target_group.web_app_tg.arn # ARN of the target group
  target_id = aws_instance.web_server_1.id # ID of the first EC2 instance to attach
  port = 80 # Port on which the instance is listening
}

resource "aws_lb_target_group_attachment" "web_server_2_attachment" {
  target_group_arn = aws_lb_target_group.web_app_tg.arn # ARN of the target group
  target_id = aws_instance.web_server_2.id # ID of the second EC2 instance to attach
  port = 80 # Port on which the instance is listening
}

# Creating an ALB Listener
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.web_app_lb.arn # ARN of the load balancer
  port = 80 # Port on which the listener will listen for incoming traffic
  protocol = "HTTP" # Protocol for the listener

  default_action {
    type = "forward" # Action type to forward traffic to the target group
    target_group_arn = aws_lb_target_group.web_app_tg.arn # ARN of the target group to forward traffic to
  }
}

# Output the DNS name of the Load Balancer
output "loadbalancerdns" {
  value = aws_lb.web_app_lb.dns_name # Outputs the DNS name of the load balancer for easy access to the web application
}