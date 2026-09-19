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
  instance_type = "c7i-flex.large"

 

  tags = {
    Name = "Terraform-Web-Server"
  }
}

output "instance_id" {
  value = aws_instance.web.ami
}

