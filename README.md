# tf-static-website
Automated deployment of a static SPA Infrastructure with Terraform.

## Getting Started

### Manual Prerequisites
Sadly, not everything can be automated. The following are steps that need to be performed prior to executing the terraform configuration.

I. Assumptions
* [Installed & Configured AWS CLI](http://docs.aws.amazon.com/cli/latest/userguide/installing.html)
* [Familiar with AWS Profiles](http://docs.aws.amazon.com/cli/latest/userguide/cli-multiple-profiles.html)
* [Installed Terraform](https://www.terraform.io/intro/getting-started/install.html)
* AWS Profile has IAM permissions to create resources

II. [Register Domain on AWS](http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar.html)

III. [Generate TLS/SSL Certificate with Amazon Certifacte Manager](http://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request.html)

### Running Terraform

To run the terraform configuration, open a terminal in the root of the directory and execute the following commands:

1. Initialize Terraform
```
terraform init
```
2. Run plan -- This will allow you to review the resources terraform will generate:
```
terraform plan
```
3. Execute terraform with apply:
```
terraform apply
```


## Architecture

http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html

http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html

## Security
TODO
