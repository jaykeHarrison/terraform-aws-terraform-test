
module "S3" {
  source = "../module"

  panda_name = "${var.panda_name}-project-b"
  domain     = var.domain
  index_html = "html/index.html"
  deploy_cloudfront = true
}