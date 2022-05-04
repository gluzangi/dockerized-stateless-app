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