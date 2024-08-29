module "S3" {
  source = "../module"

  panda_name      = "${var.panda_name}-project-a"
  domain          = var.domain
  index_html_path = "html/index.html"
}