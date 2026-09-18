**GitHub → Jenkins → Terraform → AWS**

We will build it from scratch and gradually add **validate → plan → approval → apply → destroy**.

### Target architecture

```text
                 Developer
                    │
                    │ git push
                    ▼
               ┌─────────┐
               │ GitHub  │
               └────┬────┘
                    │
              Webhook / Poll
                    │
                    ▼
             ┌─────────────┐
             │   Jenkins   │
             │             │
             │  Pipeline   │
             └──────┬──────┘
                    │
        ┌───────────┼────────────┐
        ▼           ▼            ▼
     init       validate       plan
                                  │
                              Approval
                                  │
                                  ▼
                                apply
                                  │
                                  ▼
                            ┌──────────┐
                            │   AWS    │
                            │   EC2    │
                            └──────────┘
```

## Project we will implement

We'll create an AWS EC2 instance using Terraform.

### Pipeline flow

```text
1. Developer pushes Terraform code
              ↓
2. Jenkins checks out code
              ↓
3. terraform fmt -check
              ↓
4. terraform init
              ↓
5. terraform validate
              ↓
6. terraform plan
              ↓
7. Manual approval
              ↓
8. terraform apply
              ↓
9. AWS infrastructure created
```

Then we can extend it to:

```text
DEV → QA → PROD
       │
       ├── Terraform
       ├── Jenkins
       ├── Remote State
       ├── Approval
       └── Destroy
```

---

# PART 1 — Prerequisites

We need three main machines/components:

| Component | Purpose               |
| --------- | --------------------- |
| GitHub    | Store Terraform code  |
| Jenkins   | Execute pipeline      |
| AWS       | Create infrastructure |

For the training lab, you can use:

```text
Ubuntu EC2
   │
   ├── Jenkins
   ├── Git
   ├── Terraform
   └── AWS CLI
```

Jenkins will execute Terraform directly.

---

# PART 2 — Create AWS IAM User/Role

Don't give Jenkins your personal AWS root credentials.

For a simple lab, create an IAM identity with permissions required for the resources you're going to create.

For our first EC2 lab, Jenkins needs permissions for things such as:

```text
EC2
VPC
IAM (only if your Terraform creates IAM resources)
```

For production, use a **least-privilege IAM role** rather than broad administrator permissions.

---

# PART 3 — Install Jenkins

On Ubuntu:

```bash
sudo apt update
```

Install Java:

```bash
sudo apt install fontconfig openjdk-21-jre -y
```

Check:

```bash
java -version
```

Install Jenkins using the current official Jenkins installation instructions for your Ubuntu release.

Then:

```bash
sudo systemctl enable jenkins
sudo systemctl start jenkins
```

Check:

```bash
sudo systemctl status jenkins
```

Get initial password:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Open:

```text
http://<JENKINS-IP>:8080
```

Complete the Jenkins setup.

---

# PART 4 — Install Git

On the Jenkins server:

```bash
sudo apt install git -y
```

Check:

```bash
git --version
```

---

# PART 5 — Install Terraform

Install Terraform on the Jenkins server.

After installation:

```bash
terraform version
```

You should get something similar to:

```text
Terraform v1.x.x
```

The important concept for students:

> Jenkins does not magically understand Terraform. Terraform must be installed on the Jenkins controller/agent that executes the pipeline.

---

# PART 6 — Install AWS CLI

Install AWS CLI:

```bash
sudo apt install awscli -y
```

Check:

```bash
aws --version
```

---

# PART 7 — Create GitHub Repository

Create a repository:

```text
terraform-jenkins-pipeline
```

Our repository will eventually look like:

```text
terraform-jenkins-pipeline/
│
├── provider.tf
├── variables.tf
├── main.tf
├── outputs.tf
├── terraform.tfvars
└── Jenkinsfile
```

For the first lab, keep it simple.

---

# PART 8 — Create Terraform Code

## `provider.tf`

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "us-east-1"
}
```

---

# PART 9 — Create EC2

## `main.tf`

```hcl
resource "aws_instance" "web" {

  ami           = "YOUR_AMI_ID"
  instance_type = "t2.micro"

  tags = {
    Name        = "jenkins-terraform-demo"
    Environment = "dev"
  }
}
```

Replace:

```text
YOUR_AMI_ID
```

with an AMI that exists in your selected AWS region.

---

# PART 10 — Output

Create:

## `outputs.tf`

```hcl
output "instance_id" {
  value = aws_instance.web.id
}

output "public_ip" {
  value = aws_instance.web.public_ip
}
```

After Terraform creates the EC2:

```text
instance_id
public_ip
```

will be displayed.

---

# PART 11 — Test Terraform Manually First

Before involving Jenkins, test the Terraform code.

Clone the repository:

```bash
git clone <your-github-repository>
```

Go inside:

```bash
cd terraform-jenkins-pipeline
```

Initialize:

```bash
terraform init
```

Format:

```bash
terraform fmt
```

Validate:

```bash
terraform validate
```

Plan:

```bash
terraform plan
```

Apply:

```bash
terraform apply
```

Terraform asks:

```text
Do you want to perform these actions?

  Enter a value:
```

Enter:

```text
yes
```

Check AWS.

Your EC2 should be created.

Then clean it:

```bash
terraform destroy
```

---

# PART 12 — Now Bring Jenkins Into the Picture

This is where the actual **CI/CD pipeline** starts.

Create:

```text
Jenkinsfile
```

Initial version:

```groovy
pipeline {

    agent any

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/YOUR-USERNAME/terraform-jenkins-pipeline.git'
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }

        stage('Terraform Plan') {
            steps {
                sh 'terraform plan'
            }
        }
    }
}
```

Commit:

```bash
git add .
git commit -m "Add Jenkins Terraform pipeline"
git push
```

---

# PART 13 — Create Jenkins Pipeline Job

Go to:

```text
Jenkins
   ↓
New Item
```

Enter:

```text
terraform-pipeline
```

Select:

```text
Pipeline
```

Click:

```text
OK
```

Under:

```text
Pipeline
```

select:

```text
Definition:
Pipeline script from SCM
```

SCM:

```text
Git
```

Repository:

```text
https://github.com/YOUR-USERNAME/terraform-jenkins-pipeline.git
```

Branch:

```text
*/main
```

Script Path:

```text
Jenkinsfile
```

Save.

Click:

```text
Build Now
```

---

# PART 14 — Understand What Jenkins Does

When Jenkins starts:

```text
Jenkins
   │
   ▼
Checkout
   │
   ▼
Terraform Init
   │
   ▼
Terraform Validate
   │
   ▼
Terraform Plan
```

Jenkins console output will show commands similar to:

```text
terraform init

terraform validate

terraform plan
```

This is the key concept to teach students:

> **Jenkins orchestrates the process; Terraform performs the infrastructure work.**

---

# PART 15 — Add Terraform Apply

Once `plan` is successful, add an approval stage.

```groovy
pipeline {

    agent any

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/YOUR-USERNAME/terraform-jenkins-pipeline.git'
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Terraform Format Check') {
            steps {
                sh 'terraform fmt -check'
            }
        }

        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }

        stage('Terraform Plan') {
            steps {
                sh 'terraform plan -out=tfplan'
            }
        }

        stage('Approval') {
            steps {
                input message: 'Do you want to apply Terraform changes?',
                      ok: 'Apply'
            }
        }

        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -auto-approve tfplan'
            }
        }
    }
}
```

Now your pipeline becomes:

```text
┌──────────────┐
│   Checkout   │
└──────┬───────┘
       ↓
┌──────────────┐
│     Init     │
└──────┬───────┘
       ↓
┌──────────────┐
│ Format Check │
└──────┬───────┘
       ↓
┌──────────────┐
│   Validate   │
└──────┬───────┘
       ↓
┌──────────────┐
│     Plan     │
└──────┬───────┘
       ↓
    APPROVAL
       ↓
┌──────────────┐
│    Apply     │
└──────┬───────┘
       ↓
      AWS
```

This is a good first **real-world Jenkins + Terraform pipeline**.

---

# PART 16 — Important: AWS Credentials

Don't put this in your Jenkinsfile:

```groovy
sh 'aws configure'
```

And don't do:

```groovy
sh 'export AWS_ACCESS_KEY_ID=xxxxx'
```

Instead, Jenkins should obtain AWS credentials through a secure mechanism.

For a lab, you can configure AWS credentials in:

```text
Jenkins
   ↓
Manage Jenkins
   ↓
Credentials
   ↓
System
   ↓
Global credentials
```

Then use the appropriate Jenkins AWS credential mechanism.

For production environments, a stronger design is:

```text
Jenkins
   │
   │ AssumeRole
   ▼
AWS IAM Role
   │
   ▼
AWS Resources
```

rather than storing long-lived AWS access keys.

---

# PART 17 — Better Pipeline: Separate Plan and Apply

In a real project, I recommend students understand this distinction:

### Pull Request

```text
GitHub
   ↓
Jenkins
   ↓
terraform fmt
   ↓
terraform init
   ↓
terraform validate
   ↓
terraform plan
```

No infrastructure change.

### Production deployment

```text
Git merge
   ↓
Jenkins
   ↓
terraform plan
   ↓
Manual Approval
   ↓
terraform apply
```

This gives us:

```text
           GitHub
              │
              ▼
           Jenkins
              │
       ┌──────┴──────┐
       ↓             ↓
    Validate        Plan
                     │
                  Approval
                     │
                     ▼
                   Apply
                     │
                     ▼
                    AWS
```

---

# PART 18 — Next Level: Remote Terraform State

**Don't stop at local `terraform.tfstate`.**

For a proper Jenkins + Terraform implementation, we'll next move to:

```text
                 Jenkins
                    │
                    ▼
               Terraform
                    │
                    ▼
             ┌─────────────┐
             │ S3 Backend  │
             │             │
             │ tfstate     │
             └─────────────┘
```

For modern Terraform/AWS setups, you should also consider state locking using the mechanisms supported by your Terraform/AWS versions rather than teaching the old DynamoDB-only pattern as the default.

---

# Complete learning roadmap

I suggest implementing this project in **8 stages**:

### Stage 1 — Basic

```text
GitHub
  ↓
Jenkins
  ↓
Terraform
  ↓
AWS EC2
```

### Stage 2 — Validation

```text
fmt
 ↓
init
 ↓
validate
 ↓
plan
```

### Stage 3 — Approval

```text
plan
 ↓
manual approval
 ↓
apply
```

### Stage 4 — Remote State

```text
Jenkins
   ↓
Terraform
   ↓
S3 Remote State
```

### Stage 5 — Variables

```text
dev.tfvars
qa.tfvars
prod.tfvars
```

### Stage 6 — Environments

```text
             Jenkins
                │
       ┌────────┼────────┐
       ↓        ↓        ↓
      DEV       QA      PROD
       │        │        │
       ▼        ▼        ▼
     AWS       AWS      AWS
```

### Stage 7 — Terraform Modules

```text
modules/
│
├── vpc/
├── ec2/
├── security-group/
└── alb/
```

### Stage 8 — Production-style DevSecOps

```text
Developer
    ↓
GitHub
    ↓
Jenkins
    ↓
Secret Scan
    ↓
Terraform Format
    ↓
Terraform Validate
    ↓
Security Scan
    ↓
Terraform Plan
    ↓
Manual Approval
    ↓
Terraform Apply
    ↓
AWS
    ↓
Monitoring
```
