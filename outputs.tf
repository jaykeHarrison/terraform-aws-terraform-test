output "bucket_website_endpoint" {
  value = "http://${aws_s3_bucket_website_configuration.this.website_endpoint}"
}

output "bucket_s3_name" {
  value = "s3://${aws_s3_bucket.this.bucket}"
}

output "website_url" {
  value = "https://${local.url}"
}

output "cloudfront_distribution_id" {
  value = try(aws_cloudfront_distribution.this[0].id, "")
}