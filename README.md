# lms
lms


## Deployment

### Prerequesists

Terraform
``` sh
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

### Install

Create infra

Verify the script
```sh
terraform init
```

Verify the deployment / Changes plan
```sh
terraform plan -out=tfplan
```

Apply the changes
```sh
terraform apply "tfplan"
```
