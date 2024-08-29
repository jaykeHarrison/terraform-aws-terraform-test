run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

variables {
  domain = "devopsplayground.org"
}

provider "aws" {
  region = "us-east-1"
}

run "create_cloudfront" {
  variables {
    panda_name        = run.setup_tests.random_prefix
    index_html_path   = "./tests/html/index.html"
    error_html_path   = "./tests/html/error.html"
    domain            = "pootleflump.link"
    deploy_cloudfront = true
  }
}