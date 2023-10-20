output "SQS_QUEUE_NAME" {
  value = module.sqs.queue_name
}

output "S3_BUCKET" {
  value = resource.aws_s3_bucket.this.bucket 
}

output "ECS_CLUSTER_NAME" {
  value = module.ecs.cluster_name
}

output "ECS_RUNNER_TASK_DEFINITION" {
  value = resource.aws_ecs_task_definition.runner.family
}

output "ECS_CONTAINER_NAME" {
  value = local.namespace
}

output "ECS_SECURITY_GROUP" {
  value = module.vpc.default_security_group_id
}

output "ECS_SUBNETS" {
  value = join(",", module.vpc.private_subnets)
}

output "AWS_ACCESS_KEY_ID" {
  value = resource.aws_iam_access_key.this.id
}

output "AWS_SECRET_ACCESS_KEY" {
  value = resource.aws_iam_access_key.this.secret
  sensitive = true
}