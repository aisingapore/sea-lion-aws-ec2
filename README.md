# Serving SEA-LION on AWS EC2 with LiteLLM & vLLM

## Requirements
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

## Setup
This repository aims to provide a quick and easy way to host SEA-LION on an AWS EC2 instance using LiteLLM and vLLM. 

Follow the steps below to get started:

1. Clone this repository to your local machine.
    ```
    git clone https://github.com/aisingapore/sea-lion-aws-ec2
    cd sea-lion-aws-ec2
    cp terraform.tfvars.example terraform.tfvars
    ```

2. Modify your AWS Credentials in `terraform.tfvars`

3. Run the terraform commands:
    ```
    terraform init
    terraform plan
    terraform apply
    ```

    Note the output for vLLM & LiteLLM endpoints which would be required for the 2nd part of the setup.
    
4. Run the bash script created by terraform to complete the setup:
    ```
    ./setup.sh
    ```


## Cleanup
```
terraform destroy
```