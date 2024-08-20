terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}

data "aws_s3_object" "this" {
  bucket = var.bucket_name
  key    = var.file_name
}
