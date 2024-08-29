run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

provider "aws" {
  region = "us-east-1"
}

override_resource {
  target = aws_route53_record.this[0]
}

override_resource {
  target = aws_acm_certificate.this[0]
}

run "create_cloudfront" {
  command = plan
  variables {
    panda_name        = run.setup_tests.random_prefix
    index_html_path   = "./tests/html/index.html"
    error_html_path   = "./tests/html/error.html"
    domain            = "devopsplayground.org"
    deploy_cloudfront = true
  }
}