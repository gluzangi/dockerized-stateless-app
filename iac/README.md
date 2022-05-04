<!-- BEGIN_TF_DOCS -->
# DOCKERIZED-APP-IaC : ceros-ski

## Usage
The ECR Repository must be created first, and push the dockerized Application image to the repository before provisioning the ECS Environment.

### Creating ECR Repository
```bash
terraform plan -target="module.ecr"

terraform apply -target="module.ecr"
```
_NOTE_
- To instill best practice, the refactored code implemented official Terraform AWS Provider modules whenever possible
- The infrastructure provisioning workflow uses targeted module deployment approach into building ECR stack
- ECR will scan any pushed images on the fly to screen for baked Security vulnerabilities - CVE scanned
- Docker Images pushed into ECR are set to be immutable and the repository will keep 3 revision of the image all the time
- The immutable images guarantees version based Application rollbacks are possible
- Default module variables can be overriden with identical variables defined in a `terraform.tfvars` file
- output-1 : `aws_iam_user_arn = "arn:aws:iam::<aws_account_id>:user/<iam_sa_account>"` 
- output-2 : `repository_url = "<aws_account_id>.dkr.ecr.<aws_region>.amazonaws.com/ceros-ski"` 

### Login to ECR
```bash
echo $(aws ecr get-login-password --region <aws_region> --profile <iam_sa_account>) | docker login --password-stdin --username AWS <aws_account_id>.dkr.ecr.<aws_region>.amazonaws.com/ceros-ski
```  

### Pushing a Ready Tagged Docker Image to prepare for the App deployment
```bash
docker push <aws_account_id>.dkr.ecr.<aws_region>.amazonaws.com/ceros-ski:latest
```

### Building the ECS Stack

- create the service linked role for ECS
```bash
aws iam create-service-linked-role --aws-service-name ecs.amazonaws.com --profile <iam_sa_account>
```

- launch ECS stack 
```bash
terraform plan

terraform apply

Outputs:
.
..
...
aws_iam_user_arn = "arn:aws:iam::595036287105:user/sa_account"
aws_lb_dns_name = "ceros-ski-production-ecs-2093411846.us-west-2.elb.amazonaws.com"
repository_url = "595036287105.dkr.ecr.us-west-2.amazonaws.com/ceros-ski"
vpc_id = "vpc-01e137e8af320a03a"
vpc_public_subnets = [
  "subnet-0e378c5bbe9bbd3af",
  "subnet-0fdf905782582e80d",
]
```

### TechDebt
- Current container orchestration mechanism is with ECS using Container Instances (EC2 instances running ECS container Agent)
- Consider migration into AWS Fargate/EKS automanaged container orchestration framework
- DNS Record management of the Application
- TLS/SSL setup to serve the Application over HTTPS

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ecr"></a> [ecr](#module\_ecr) | terraform-aws-modules/ecr/aws | 1.1.1 |
| <a name="module_key_pair"></a> [key\_pair](#module\_key\_pair) | terraform-aws-modules/key-pair/aws | 1.0.1 |
| <a name="module_security_group"></a> [security\_group](#module\_security\_group) | terraform-aws-modules/security-group/aws | 4.9.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 3.14.0 |

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_ecs_cluster.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_service.backend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.backend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_instance_profile.ecs_agent](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.ecs_agent](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.ecs_agent](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ecs_agent](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_launch_configuration.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_configuration) | resource |
| [aws_lb.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.backend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.backend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_iam_policy_document.ecs_agent](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecs_agent_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_role.ecs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_iam_user.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_user) | data source |
| [aws_ssm_parameter.cluster_ami_id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_credentials_file"></a> [aws\_credentials\_file](#input\_aws\_credentials\_file) | File containing AWS credentials | `string` | `"~/.aws/credentials"` | no |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS Account Profile/IAM User | `string` | `"sa_auto"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region To Provision Cloud Resources | `string` | `"us-west-2"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Name of the Provisoned Environment | `string` | `"production"` | no |
| <a name="input_repository_name"></a> [repository\_name](#input\_repository\_name) | Name of the Docker Image Private Registry | `string` | `"ceros-ski"` | no |
| <a name="input_service_account_key"></a> [service\_account\_key](#input\_service\_account\_key) | Management/Service Account SSH Public Key | `string` | `"~/.ssh/id_rsa.pub"` | no |
| <a name="input_vpc_azs"></a> [vpc\_azs](#input\_vpc\_azs) | Availability zones for VPC | `list(string)` | <pre>[<br>  "us-west-2a",<br>  "us-west-2c"<br>]</pre> | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for VPC | `string` | `"172.0.0.0/16"` | no |
| <a name="input_vpc_enable_nat_gateway"></a> [vpc\_enable\_nat\_gateway](#input\_vpc\_enable\_nat\_gateway) | Enable NAT gateway for VPC | `bool` | `true` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | Name of VPC | `string` | `"vpc-ceros-ski"` | no |
| <a name="input_vpc_one_nat_gateway_per_az"></a> [vpc\_one\_nat\_gateway\_per\_az](#input\_vpc\_one\_nat\_gateway\_per\_az) | Enable One NAT gateway per Availability Zone for VPC | `bool` | `true` | no |
| <a name="input_vpc_public_subnets"></a> [vpc\_public\_subnets](#input\_vpc\_public\_subnets) | Public subnets for VPC | `list(string)` | <pre>[<br>  "172.0.1.0/24",<br>  "172.0.3.0/24"<br>]</pre> | no |
| <a name="input_vpc_single_nat_gateway"></a> [vpc\_single\_nat\_gateway](#input\_vpc\_single\_nat\_gateway) | Enable Single NAT gateway for VPC | `bool` | `true` | no |
| <a name="input_vpc_tags"></a> [vpc\_tags](#input\_vpc\_tags) | Tags for resources in VPC module | `map(string)` | <pre>{<br>  "Application": "ceros-ski"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_iam_user_arn"></a> [aws\_iam\_user\_arn](#output\_aws\_iam\_user\_arn) | ARN value of current AWS IAM User |
| <a name="output_aws_lb_dns_name"></a> [aws\_lb\_dns\_name](#output\_aws\_lb\_dns\_name) | LoadBalancer DNS Name of ECS Cluster |
| <a name="output_repository_url"></a> [repository\_url](#output\_repository\_url) | The URL of the repository |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the provisioned VPC |
| <a name="output_vpc_public_subnets"></a> [vpc\_public\_subnets](#output\_vpc\_public\_subnets) | IDs of public subnets in the VPC |
<!-- END_TF_DOCS -->