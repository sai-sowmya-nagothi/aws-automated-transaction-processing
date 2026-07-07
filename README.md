# AWS Automated Transaction Processing
 
This project implements an automated transaction-processing workflow using AWS services and Infrastructure as Code.
 
## Project Requirements
 
- EC2 instance validation
- ECS task execution
- VPC networking with subnets and security groups
- AWS Step Functions workflow orchestration
- Infrastructure deployment using Terraform
- GitHub-based version control and deployment
- Single IAM role for GitHub infrastructure deployment
- Automated transaction file processing
 
## Project Structure
 
- `terraform/` - AWS infrastructure as code
- `lambda/` - Transaction-processing Lambda code
- `ecs/` - ECS application files
- `.github/workflows/` - GitHub Actions deployment workflows
- `docs/` - Project documentation and evidence
## Infrastructure Deployment
 
Infrastructure is managed using Terraform.
 
The deployment workflow performs:
 
1. Repository checkout
2. AWS authentication
3. Terraform setup
4. Terraform initialization
5. Terraform formatting validation
6. Terraform configuration validation
7. Terraform plan
 
GitHub Actions uses a single IAM deployment role instead of long-lived AWS access keys.
 
## End-to-End Demo
 
Run the complete workflow from the project root:
 
```bash
./demo.sh
```text
