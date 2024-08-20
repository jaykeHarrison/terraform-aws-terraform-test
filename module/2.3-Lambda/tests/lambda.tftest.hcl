run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

run "create_lambda" {
  variables {
    prefix      = run.setup_tests.lambda_prefix
    lambda_name = "${run.setup_tests.lambda_prefix}-panda-lambda"
  }

  assert {
    condition     = aws_lambda_function.this.function_name == "${run.setup_tests.lambda_prefix}-panda-lambda"
    error_message = "Invalid bucket name"
  }
}

run "invoke_lambda" {
  module {
    source = "./tests/invoke_lambda"
  }

  variables {
    lambda_function_name = "${run.setup_tests.lambda_prefix}-panda-lambda"
    lambda_payload = {
      "bucket_name" : "jayke-funky-panda-test-bucket",
      "file_name" : "my_file.txt",
      "content" : "This is the content of the file."
    }
  }
}

run "s3_object_created" {
  module {
    source = "./tests/s3_object_created"
  }

  variables {
    bucket_name = "jayke-funky-panda-test-bucket"
    file_name   = "my_file.txt"
  }

  assert {
    condition     = data.aws_s3_object.this.key == "my_file.txt"
    error_message = "lambda did not create file"
  }
}