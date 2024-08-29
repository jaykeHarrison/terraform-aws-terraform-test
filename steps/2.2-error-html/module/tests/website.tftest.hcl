run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

variables {
  index_html_path = "./tests/html/index.html"
}

run "create_bucket" {
  variables {
    panda_name = run.setup_tests.random_prefix
    domain     = "devopsplayground.org"
  }

  # Check that the bucket name is correct
  assert {
    condition     = aws_s3_bucket.this.bucket == "${var.panda_name}.${var.domain}"
    error_message = "Invalid bucket name"
  }

  # Check index.html hash matches
  assert {
    condition     = aws_s3_object.index.etag == filemd5("./tests/html/index.html")
    error_message = "Invalid eTag for index.html"
  }
}

run "create_error_page" {
  variables {
    panda_name      = run.setup_tests.random_prefix
    domain          = "devopsplayground.org"
    error_html_path = "./tests/html/error.html"
  }

  # Check index.html hash matches
  assert {
    condition     = aws_s3_object.error[0].etag == filemd5("./tests/html/error.html")
    error_message = "Invalid hash for error.html"
  }
}