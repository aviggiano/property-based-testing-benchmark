output "SQS_QUEUE_NAME" {
  value = module.sqs.queue_name
}

output "S3_BUCKET" {
  value = resource.aws_s3_bucket.this.bucket 
}

output "AWS_ACCESS_KEY_ID" {
  value = resource.aws_iam_access_key.this.id
}

output "AWS_SECRET_ACCESS_KEY" {
  value = resource.aws_iam_access_key.this.secret
  sensitive = true
}