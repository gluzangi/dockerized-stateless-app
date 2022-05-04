/**
* # DOCKERIZED-APP-IaC : ceros-ski
*/

terraform {
  required_version = ">= 1.1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  shared_credentials_files = [ var.aws_credentials_file ]
  profile = var.aws_profile

  default_tags {
    tags = {
      Terraform   = "true"
      Name        = "Dockerization Project"
      Owner       = "DevOps Team"
      Environment = var.environment
    }
  }
}

data "aws_iam_user" "current" {
  user_name = var.aws_profile
}

/******************************************************************************
* VPC : main.tf
*******************************************************************************/

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"

  name    = var.vpc_name
  cidr    = var.vpc_cidr

  azs                   = var.vpc_azs
  public_subnets        = var.vpc_public_subnets

  enable_nat_gateway    = var.vpc_enable_nat_gateway
  enable_dns_support    = true
  enable_dns_hostnames  = true

  tags = merge(var.vpc_tags, {Resource = "modules.vpc"})
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.9.0"

  name                = "ceros-ecs-asg-sg"
  description         = "Security Group For AutoScalingGroup and ECS Cluster"

  vpc_id              = module.vpc.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]

  ingress_rules = ["ssh-tcp", "http-80-tcp", "http-8080-tcp", "https-443-tcp", "all-icmp"]
  egress_rules  = ["all-all"]

  tags = {
    Application = "ceros-ski"
    Environment = var.environment
    Resource = "modules.security_group.ecs_asg"
  }
}

module "key_pair" {
  source      = "terraform-aws-modules/key-pair/aws"
  version     = "1.0.1"

  key_name    = "sa-account-key"
  public_key  = file(var.service_account_key)

  tags = var.vpc_tags
}

/******************************************************************************
* ECR  : main.tf
*******************************************************************************/

module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "1.1.1"

  repository_name = var.repository_name

  repository_read_write_access_arns = [data.aws_iam_user.current.arn]
  repository_lifecycle_policy       = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 3 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 3
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
  repository_image_tag_mutability = "IMMUTABLE"
  repository_image_scan_on_push = "true"  

  tags = var.vpc_tags
}

/******************************************************************************
* ECS  : main.tf
*******************************************************************************/

/**
* The ECS Cluster and its services and task groups. 
*
* The ECS Cluster has no dependencies, but will be referenced in the launch
* configuration, may as well define it first for clarity's sake.
*/

resource "aws_ecs_cluster" "cluster" {
  name = "ceros-ski-${var.environment}"

  tags = {
    Application = "ceros-ski"
    Environment = var.environment
    Resource = "aws_ecs_cluster.cluster"
  }
}

/*******************************************************************************
* AutoScaling Group
*
* The autoscaling group that will generate the instances used by the ECS
* cluster.
*
********************************************************************************/

/**
* The IAM policy needed by the ecs agent to allow it to manage the instances
* that back the cluster.  This is the terraform structure that defines the
* policy.
*/
data "aws_iam_policy_document" "ecs_agent" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeTags",
      "ecs:CreateCluster",
      "ecs:DeregisterContainerInstance",
      "ecs:DiscoverPollEndpoint",
      "ecs:Poll",
      "ecs:RegisterContainerInstance",
      "ecs:StartTelemetrySession",
      "ecs:UpdateContainerInstancesState",
      "ecs:Submit*",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "*"
    ]
  }
}

/**
* The policy resource itself.  Uses the policy document defined above.
*/
resource "aws_iam_policy" "ecs_agent" {
  name = "ceros-ski-${var.environment}-ecs-agent-policy"
  path = "/"
  description = "Access policy for the EC2 instances backing the ECS cluster."

  policy = data.aws_iam_policy_document.ecs_agent.json
}

/**
* A policy document defining the assume role policy for the IAM role below.
* This is required.
*/
data "aws_iam_policy_document" "ecs_agent_assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }

}

/**
* The IAM role that will be used by the instances that back the ECS Cluster.
*/
resource "aws_iam_role" "ecs_agent" {
  name = "ceros-ski-${var.environment}-ecs-agent"
  path = "/"

  assume_role_policy = data.aws_iam_policy_document.ecs_agent_assume_role_policy.json
}

/**
* Attatch the ecs_agent policy to the role.  The assume_role policy is attached
* above in the role itself.
*/
resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role = aws_iam_role.ecs_agent.name 
  policy_arn = aws_iam_policy.ecs_agent.arn 
}

/**
* The Instance Profile that associates the IAM resources we just finished
* defining with the launch configuration.
*/
resource "aws_iam_instance_profile" "ecs_agent" {
  name = "ceros-ski-${var.environment}-ecs-agent"
  role = aws_iam_role.ecs_agent.name 
}

/** 
* This parameter contains the AMI ID of the ECS Optimized version of Amazon
* Linux 2 maintained by AWS.  We'll use it to launch the instances that back
* our ECS cluster.
*/
data "aws_ssm_parameter" "cluster_ami_id" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

/**
* The launch configuration for the autoscaling group that backs our cluster.  
*/
resource "aws_launch_configuration" "cluster" {
  name          = "ceros-ski-${var.environment}-cluster"
  image_id      = data.aws_ssm_parameter.cluster_ami_id.value 
  instance_type = "t3.micro"
  key_name      = module.key_pair.key_pair_key_name

  iam_instance_profile = aws_iam_instance_profile.ecs_agent.name
  security_groups      = [module.security_group.security_group_id]

  // Register our EC2 instances with the correct ECS cluster.
  user_data = <<EOF
#!/bin/bash
echo "ECS_CLUSTER=${aws_ecs_cluster.cluster.name}" >> /etc/ecs/ecs.config
EOF
}

/**
* The autoscaling group that backs our ECS cluster.
*/
resource "aws_autoscaling_group" "cluster" {
  name = "ceros-ski-${var.environment}-cluster"
  min_size = 2
  max_size = 2 
  
  vpc_zone_identifier = module.vpc.public_subnets
  launch_configuration = aws_launch_configuration.cluster.name

  tag {
    key = "Application"
    value = "ceros-ski"
    propagate_at_launch = true
  }

  tag {
    key = "Environment"
    value = var.environment
    propagate_at_launch = true
  }

  tag {
    key   = "Resource"
    value = "aws_autoscaling_group.cluster"
    propagate_at_launch = true
  }
}

/******************************************************************************
 * Load Balancer
 *
 * The load balancer that will direct traffic to our backend services.
 ******************************************************************************/

/**
* The load balancer that is used by the ECS Services. 
*/
resource "aws_lb" "ecs" {
  name = "ceros-ski-${var.environment}-ecs"
  internal = false
  load_balancer_type = "application"
  security_groups = [module.security_group.security_group_id]
  subnets = module.vpc.public_subnets

  tags = {
    Application = "ceros-ski" 
    Environment = var.environment
    Resource = "aws_lb.ecs"
  }
}

/**
* A target group to use with ceros-ski's backend ECS service.
*/
resource "aws_lb_target_group" "backend" {
  name = "ceros-ski-${var.environment}-backend"
  port = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id = module.vpc.vpc_id

  tags = {
    Application = "ceros-ski" 
    Environment = var.environment 
    Resource = "aws_lb_target_group.backend"
  }
}

/**
* Wire the backend service up to the load balancer in the ecs_cluster.
*/
resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.ecs.arn 
  port = "80"
  protocol = "HTTP"
 
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

/******************************************************************************
 *  ECS Service
 *
 *  The task and service definitions for our backend ECS Service.
 ******************************************************************************/

/**
* Create the task definition for the ceros-ski backend, in this case a thin
* wrapper around the container definition.
* 
* "image": "${var.repository_url}:latest",
*/
resource "aws_ecs_task_definition" "backend" {
  family = "ceros-ski-${var.environment}-backend"
  network_mode = "bridge"

  container_definitions = <<EOF
[
  {
    "name": "ceros-ski",
    "image": "${module.ecr.repository_url}:latest",
    "environment": [
      {
        "name": "PORT",
        "value": "80"
      }
    ],
    "cpu": 512,
    "memoryReservation": 512,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80,
        "protocol": "tcp"
      }
    ]
  }
]
EOF

  tags = {
    Application = "ceros-ski" 
    Environment = var.environment 
    Name = "ceros-ski-${var.environment}-backend"
    Resource = "aws_ecs_task_definition.backend"
  }
}

/**
* This role is automatically created by ECS the first time we try to use an ECS
* Cluster.  By the time we attempt to use it, it should exist.  However, there
* is a possible TECHDEBT race condition here.  I'm hoping terraform is smart
* enough to handle this - but I don't know that for a fact. By the time I tried
* to use it, it already existed.
*/
data "aws_iam_role" "ecs_service" {
  name = "AWSServiceRoleForECS"
}

/**
* Create the ECS Service that will wrap the task definition.  Used primarily to
* define the connections to the load balancer and the placement strategies and
* constraints on the tasks.
*/
resource "aws_ecs_service" "backend" {
  name = "ceros-ski-${var.environment}-backend"
  cluster = aws_ecs_cluster.cluster.id 
  task_definition = aws_ecs_task_definition.backend.arn

  iam_role        = data.aws_iam_role.ecs_service.arn
  
  desired_count = 2 
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent = 100

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name = "ceros-ski"
    container_port = "80"
  } 

  tags = {
    Application = "ceros-ski" 
    Environment = var.environment 
    Resource = "aws_ecs_service.backend"
  }
}
