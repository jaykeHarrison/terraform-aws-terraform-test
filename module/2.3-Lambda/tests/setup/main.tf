terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}

locals {
  bucket_name = "${random_pet.lambda_prefix.id}-playground-bucket"
}

resource "random_pet" "lambda_prefix" {
  length = 4
}

# resource "aws_s3_bucket" "s3_bucket" {
#   bucket = local.bucket_name
# }

# resource "aws_s3_bucket_public_access_block" "s3_bucket" {
#   bucket = aws_s3_bucket.s3_bucket.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# resource "aws_s3_bucket_ownership_controls" "s3_bucket" {
#   bucket = aws_s3_bucket.s3_bucket.id

#   rule {
#     object_ownership = "BucketOwnerPreferred"
#   }
# }

output "lambda_prefix" {
  value = random_pet.lambda_prefix.id
}

output "bucket_name" {
  value = local.bucket_name
}