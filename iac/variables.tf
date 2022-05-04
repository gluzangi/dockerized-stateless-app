/******************************************************************************
* Default/Initialized Variables For TF AWS Modules 
*******************************************************************************/

variable "aws_region" {
  description = "AWS Region To Provision Cloud Resources"
  type        = string
  default     = "us-west-2"
}

variable "aws_profile" {
  description = "AWS Account Profile/IAM User"
  type        = string
  default     = "sa_auto"
}

variable "aws_credentials_file" {
  description = "File containing AWS credentials"
  type        = string
  default     = "~/.aws/credentials"
}

variable "environment" {
  description = "Name of the Provisoned Environment"
  type        = string
  default     = "production"
}

variable "repository_name" {
  description = "Name of the Docker Image Private Registry"
  type        = string
  default     = "ceros-ski"
}

variable "service_account_key" {
  description = "Management/Service Account SSH Public Key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "vpc_name" {
  description = "Name of VPC"
  type        = string
  default     = "vpc-ceros-ski"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "172.0.0.0/16"
}

variable "vpc_azs" {
  description = "Availability zones for VPC"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2c"]
}

variable "vpc_public_subnets" {
  description = "Public subnets for VPC"
  type        = list(string)
  default     = ["172.0.1.0/24", "172.0.3.0/24"]
}

variable "vpc_enable_nat_gateway" {
  description = "Enable NAT gateway for VPC"
  type        = bool
  default     = true
}

variable "vpc_single_nat_gateway" {
  description = "Enable Single NAT gateway for VPC"
  type        = bool
  default     = true
}

variable "vpc_one_nat_gateway_per_az" {
  description = "Enable One NAT gateway per Availability Zone for VPC"
  type        = bool
  default     = true
}

variable "vpc_tags" {
  description = "Tags for resources in VPC module"
  type        = map(string)
  default = {
    Application = "ceros-ski"
  }
}
