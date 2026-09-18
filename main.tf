terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
region = "us-east-1"
}

resource "aws_instance" "web" {
ami           = "ami-0b6d9d3d33ba97d99"
instance_type = "t3.micro"

user_data = <<-EOF
              #!/bin/bash

              apt-get update -y

              apt-get install -y ansible

              ansible --version
              EOF

  tags = {
    Name = "Terraform-Web-Server"
  }
}

output "instance_id" {
  value = aws_instance.web.ami
}

