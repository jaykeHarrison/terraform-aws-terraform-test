variable "panda_name" {}

variable "domain" {}

variable "index_html_path" {}

variable "error_html_path" {
  description = "Path to the custom error document file to upload (e.g., 404.html)."
  type        = string
  default     = null
}