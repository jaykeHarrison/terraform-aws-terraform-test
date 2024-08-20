# variable "bucket_name" {
#   description = "Name of the s3 bucket. Must be unique."
#   default     = null
#   type        = string
# }

variable "prefix" {
  description = "prefix to be used for resources"
  type        = string
}

variable "lambda_name" {
  description = "name of the Lambda Function"
  type        = string
}