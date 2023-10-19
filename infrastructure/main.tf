terraform {
  required_version = "~> 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.56"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

locals {
  namespace = "property-benchmark"
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = { Namespace = local.namespace }
  }
}

# * Give Docker permission to pusher Docker images to AWS
data "aws_caller_identity" "this" {}
data "aws_ecr_authorization_token" "this" {}
data "aws_region" "this" {}
locals { ecr_address = format("%v.dkr.ecr.%v.amazonaws.com", data.aws_caller_identity.this.account_id, data.aws_region.this.name) }
provider "docker" {
  host = var.docker_host
  registry_auth {
    address  = local.ecr_address
    password = data.aws_ecr_authorization_token.this.password
    username = data.aws_ecr_authorization_token.this.user_name
  }
}

module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 1.6.0"

  repository_force_delete = true
  # https://stackoverflow.com/a/75131873/1849920
  repository_image_tag_mutability = "MUTABLE"
  repository_name                 = local.namespace
  repository_lifecycle_policy = jsonencode({
    rules = [{
      action       = { type = "expire" }
      description  = "Delete all images except a handful of the newest images"
      rulePriority = 1
      selection = {
        countNumber = 3
        countType   = "imageCountMoreThan"
        tagStatus   = "any"
      }
    }]
  })
}

resource "null_resource" "docker_build" {
  # https://stackoverflow.com/questions/68658353/push-docker-image-to-ecr-using-terraform
  # https://stackoverflow.com/questions/75131872/error-failed-to-solve-failed-commit-on-ref-unexpected-status-400-bad-reques
  provisioner "local-exec" {
    command = "aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${module.ecr.repository_url} && docker buildx build --platform linux/amd64 -t ${module.ecr.repository_url}:latest .. --push --provenance=false"
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

resource "docker_image" "this" {
  name       = "${module.ecr.repository_url}:latest"
  depends_on = [null_resource.docker_build]
}


# * Push our container image to our ECR.
resource "docker_registry_image" "this" {
  keep_remotely = true # Do not delete old images when a new image is pushed
  name          = resource.docker_image.this.name
}


data "aws_availability_zones" "available" { state = "available" }
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.19.0"

  azs                = slice(data.aws_availability_zones.available.names, 0, 2) # Span subnetworks across 2 avalibility zones
  cidr               = "10.0.0.0/16"
  create_igw         = true # Expose public subnetworks to the Internet
  enable_nat_gateway = true # Hide private subnetworks behind NAT Gateway
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24"]
  single_nat_gateway = true
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 4.1.3"

  cluster_name = local.namespace

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }
}


resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "this" {
  name = "/ecs/${local.namespace}"
}

resource "aws_ecs_task_definition" "this" {
  container_definitions = jsonencode([{
    environment : [
      { name = "SQS_QUEUE_NAME", value = module.sqs.queue_name },
      { name = "S3_BUCKET", value = resource.aws_s3_bucket.this.bucket },
      { name = "AWS_ACCESS_KEY_ID", value = resource.aws_iam_access_key.this.id },
      { name = "AWS_SECRET_ACCESS_KEY", value = resource.aws_iam_access_key.this.secret },
    ],
    essential = true,
    image     = resource.docker_registry_image.this.name,
    name      = local.namespace,
    command   = ["python3", "-m", "benchmark", "consumer"]
    logConfiguration : {
      logDriver = "awslogs",
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.this.name,
        "awslogs-region"        = data.aws_region.this.name,
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
  cpu                      = 256
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  family                   = "family-of-${local.namespace}-tasks"
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
}


resource "aws_ecs_service" "this" {
  cluster         = module.ecs.cluster_id
  desired_count   = 1
  launch_type     = "FARGATE"
  name            = "${local.namespace}-service"
  task_definition = resource.aws_ecs_task_definition.this.arn

  lifecycle {
    ignore_changes = [desired_count] # Allow external changes to happen without Terraform conflicts, particularly around auto-scaling.
  }

  network_configuration {
    security_groups = [module.vpc.default_security_group_id]
    subnets         = module.vpc.private_subnets
  }
}

# * S3
resource "aws_s3_bucket" "this" {
  bucket = "${local.namespace}-bucket"
}

# * SQS
module "sqs" {
  source = "terraform-aws-modules/sqs/aws"

  name = "${local.namespace}-queue"

  create_dlq = true
}

# * IAM User
resource "aws_iam_user" "this" {
  name = "${local.namespace}-user"
}

resource "aws_iam_access_key" "this" {
  user = aws_iam_user.this.name
}

data "aws_iam_policy_document" "this" {
  statement {
    effect    = "Allow"
    actions   = ["sqs:*"]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["${resource.aws_s3_bucket.this.arn}/*"]
  }
}

resource "aws_iam_user_policy" "this" {
  name   = "${local.namespace}-user-policy"
  user   = aws_iam_user.this.name
  policy = data.aws_iam_policy_document.this.json
}
