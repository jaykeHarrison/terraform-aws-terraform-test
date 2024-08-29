run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

variables {
  domain = "devopsplayground.org"
}

run "create_s3_website" {
  variables {
    panda_name      = run.setup_tests.random_prefix
    index_html_path = "./tests/html/index.html"
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

run "add_error_page" {
  variables {
    panda_name      = run.setup_tests.random_prefix
    index_html_path = "./tests/html/index.html"
    error_html_path = "./tests/html/error.html"
  }

  # Check error.html hash matches
  assert {
    condition     = aws_s3_object.error[0].etag == filemd5("./tests/html/error.html")
    error_message = "Invalid eTag for error.html"
  }
}

override_resource {
  target = aws_cloudfront_distribution.this[0]
}

override_resource {
  target = aws_route53_record.cloudfront_alias[0]
}

run "create_acm_certificate" {
  variables {
    panda_name        = run.setup_tests.random_prefix
    index_html_path   = "./tests/html/index.html"
    error_html_path   = "./tests/html/error.html"
    domain            = "pootleflump.link"
    deploy_cloudfront = true
  }

  assert {
    condition       = aws_acm_certificate.this[0].domain_name == "${var.panda_name}.${var.domain}"
    error_message = "Invalid FQDN for ACM certificate"
  }

  assert {
    condition       = length(split("${var.panda_name}.${var.domain}", aws_route53_record.this[0].fqdn)) > 1
    error_message = "Invalid FQDN for record"
  }
}

