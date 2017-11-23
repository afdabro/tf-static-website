# tf-static-website
Static SPA Infrastructure with Terraform

## Getting Started

### Manual Prerequisites

I. Assumptions
* Installed & Configured AWS CLI
* Installed Terraform

II. Register Domain

III. Generate TLS/SSL Certificate with ACM

### Running Terraform

1. Initialize Terraform
```
terraform init
```
2. Install Terraform dependencies:
```
terraform get
```
3. Run plan to review the resources terraform will generate:
```
terraform plan
```
4. Execute terraform with apply:
```
terraform apply
```


## Architecture

http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html

http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html

## Security
TODO

https://policy.security.harvard.edu/view-data-security-level


