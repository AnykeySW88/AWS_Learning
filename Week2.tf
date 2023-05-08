provider "aws" {
  region = "us-west-2"
}

# Create an S3 bucket and upload a file using the init-s3.sh script
resource "null_resource" "s3_setup" {
  provisioner "local-exec" {
    command = "./init-s3.sh"
  }
}

# Create an EC2 instance
resource "aws_instance" "ec2_instance" {
  ami           = "ami-0747e613a2a1ff483"
  instance_type = "t2.micro"

  # Configure access to S3 service
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  # Add user data to download file from S3 during instance startup
  user_data = <<-EOF
              #!/bin/bash
              aws s3 cp s3://${var.s3_bucket_name}/myfile.txt /home/ec2-user/myfile.txt
              EOF

  # Allow HTTP and SSH access
  security_groups = ["${aws_security_group.ec2_instance_sg.id}"]
}

# Create an IAM instance profile to grant access to S3 service
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_instance_role.id
}

# Create an IAM role with S3 access policy
resource "aws_iam_role" "ec2_instance_role" {
  name = "ec2_instance_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  # Grant S3 access to the role
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/*"
      }
    ]
  })
}

# Create an EC2 instance security group to allow HTTP and SSH access
resource "aws_security_group" "ec2_instance_sg" {
  name_prefix = "ec2_instance_sg-"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define variables
variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket to create"
}
