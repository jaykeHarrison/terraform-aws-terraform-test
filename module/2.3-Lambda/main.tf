provider "aws" {
  region = "eu-west-1"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "main.py"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "this" {
  function_name    = var.lambda_name
  role             = aws_iam_role.lambda.arn
  filename         = "lambda_function_payload.zip"
  handler          = "main.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.11"
}

# resource "aws_lambda_layer_version" "this" {}

# resource "aws_lambda_function_event_invoke_config" "this" {}

# resource "aws_lambda_permission" "current_version_triggers" {}

# resource "aws_lambda_permission" "unqualified_alias_triggers" {}

# resource "aws_lambda_event_source_mapping" "this" {}

# resource "aws_lambda_function_url" "this" {}
