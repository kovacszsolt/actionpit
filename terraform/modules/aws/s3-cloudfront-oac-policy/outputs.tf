output "bucket_name" {
  description = "S3 bucket name with CloudFront OAC policy attached."
  value       = data.aws_s3_bucket.main.id
}
