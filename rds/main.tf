# Configure AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# Fetch the Default VPC
data "aws_vpc" "default" {
  default = true
}

# Fetch Default Subnet IDs
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Create a Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "cbz-rds-sg"
  description = "Allow MySQL access to RDS"
  vpc_id      = data.aws_vpc.default.id

  # Restrict access to your IP or application security group.
  # Replace this example with your actual trusted client IP.
  ingress {
    description = "MySQL access"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["YOUR_PUBLIC_IP/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

# Create a DB Subnet Group
resource "aws_db_subnet_group" "default" {
  name       = "cbz-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "cbz-db-subnet-group"
  }
}

# Create an RDS MySQL Instance
resource "aws_db_instance" "cbz_db_instance" {
  identifier             = "cbz-mysql-db"
  allocated_storage      = 20
  max_allocated_storage  = 100
  storage_type           = "gp3"

  engine         = "mysql"
  engine_version = "8.0"

  instance_class = "db.t3.micro"

  username = "admin"

  # Supply the password through a sensitive Terraform variable.
  password = var.db_password

  parameter_group_name = "default.mysql8.0"

  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.default.name

  backup_retention_period = 1
  skip_final_snapshot     = true

  tags = {
    Name = "cbz-db-instance"
  }
}
