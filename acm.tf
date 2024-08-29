resource "aws_acm_certificate" "this" {
  count = var.deploy_cloudfront ? 1 : 0

  domain_name       = local.url
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "this" {
  count = var.deploy_cloudfront ? 1 : 0

  name = var.domain
}

resource "aws_route53_record" "this" {
  count = var.deploy_cloudfront ? 1 : 0

  zone_id = data.aws_route53_zone.this[0].zone_id
  name    = tolist(aws_acm_certificate.this[0].domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.this[0].domain_validation_options)[0].resource_record_type
  records = [tolist(aws_acm_certificate.this[0].domain_validation_options)[0].resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "this" {
  count = var.deploy_cloudfront ? 1 : 0
  
  certificate_arn         = aws_acm_certificate.this[0].arn
  validation_record_fqdns = [aws_route53_record.this[0].fqdn]
}
