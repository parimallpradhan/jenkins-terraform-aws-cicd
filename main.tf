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

  user_data = <<-EOF
              #!/bin/bash

              apt-get update -y

                sudo apt update
                sudo apt install fontconfig openjdk-21-jre
                java -version  

                sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
                https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
                echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
                https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
                /etc/apt/sources.list.d/jenkins.list > /dev/null
                sudo apt update
                sudo apt install jenkins

              EOF

  tags = {
    Name = "Terraform-Web-Server"
  }
}

output "instance_id" {
  value = aws_instance.web.ami
}

