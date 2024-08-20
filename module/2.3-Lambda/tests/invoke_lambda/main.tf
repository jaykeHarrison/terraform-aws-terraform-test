terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}

resource "aws_lambda_invocation" "example" {
  function_name = var.lambda_function_name

  input = jsonencode(var.lambda_payload)
}

output "result_entry" {
  value = jsondecode(aws_lambda_invocation.example.result)
}

output "bucket_name" {
  value = var.lambda_payload.bucket_name
}