resource "aws_s3_bucket" "domain_logs_bucket" {
  bucket = "logs.${var.domain}"
  acl    = "log-delivery-write"
  tags {
    Name        = "logs.${var.domain}"
    Environment = "${var.environment_tag}"
    Owner = "${var.owner_tag}"
    Project = "${var.project_tag}"
    Confidentiality = "${var.confidentiality_tag}"
    Compliance = "${var.compliance_tag}"
  }
  lifecycle_rule {
    id      = "log"
    enabled = true

    prefix  = "logs/"
    tags {
      "rule"      = "log"
      "autoclean" = "true"
    }
    // Only keep last 30 days
    expiration {
      days = 30
    }
  }
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
}

resource "aws_s3_bucket" "domain-spa" {
  bucket = "${var.domain}"
  website {
    index_document = "index.html"
  }
  logging {
    target_bucket = "${aws_s3_bucket.domain_logs_bucket.id}"
    target_prefix = "logs/s3/"
  }
  tags {
    Name        = "${var.domain}"
    Environment = "${var.environment_tag}"
    Owner = "${var.owner_tag}"
    Project = "${var.project_tag}"
    Confidentiality = "${var.confidentiality_tag}"
    Compliance = "${var.compliance_tag}"
  }
}

data "aws_iam_policy_document" "s3_policy_domain" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.domain-spa.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["${aws_s3_bucket.domain-spa.arn}"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
    }
  }
}

resource "aws_s3_bucket_policy" "domain-spa" {  
    bucket = "${aws_s3_bucket.domain-spa.bucket}"
    policy = "${data.aws_iam_policy_document.s3_policy_domain.json}"
}

resource "aws_s3_bucket" "subdomain-spa" {
  bucket = "www.${var.domain}"
  website {
    redirect_all_requests_to = "${var.domain}"
  }
  tags {
    Name        = "www.${var.domain}"
    Environment = "${var.environment_tag}"
    Owner = "${var.owner_tag}"
    Project = "${var.project_tag}"
    Confidentiality = "${var.confidentiality_tag}"
    Compliance = "${var.compliance_tag}"
  }
}

data "aws_iam_policy_document" "s3_policy_subdomain" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.subdomain-spa.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["${aws_s3_bucket.subdomain-spa.arn}"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
    }
  }
}

resource "aws_s3_bucket_policy" "subdomain-spa" {  
    bucket = "${aws_s3_bucket.subdomain-spa.bucket}"
    policy = "${data.aws_iam_policy_document.s3_policy_subdomain.json}"
}

data "aws_acm_certificate" "cert" {
  domain   = "${var.domain}"
  statuses = ["ISSUED"]
}

resource "aws_cloudfront_distribution" "domain_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.domain-spa.bucket_domain_name}"
    origin_id   = "${var.origin_id}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path}"
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = "logs.${var.domain}"
    prefix          = "logs/cdn/"
  }

  aliases = ["www.${var.domain}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.origin_id}"
    compress = true
    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  custom_error_response {
      error_caching_min_ttl = 0
      error_code = "404"
      response_code = "200"
      response_page_path = "/index.html"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA"]
    }
  }

  tags {
    Name     = "cloudfront.${var.domain}"
    Environment = "${var.environment_tag}"
    Owner = "${var.owner_tag}"
    Project = "${var.project_tag}"
    Confidentiality = "${var.confidentiality_tag}"
    Compliance = "${var.compliance_tag}"
  }

  viewer_certificate {
    acm_certificate_arn = "${data.aws_acm_certificate.cert.arn}"
    minimum_protocol_version = "TLSv1_2016"
    ssl_support_method = "sni-only"
  }
}

// Route 53
resource "aws_route53_zone" "main" {
  name = "${var.domain}"
  tags {
    Name     = "route53-${var.domain}"
    Environment = "${var.environment_tag}"
    Owner = "${var.owner_tag}"
    Project = "${var.project_tag}"
  }
}

resource "aws_route53_record" "root-a" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name    = "${var.domain}"
  type    = "A"
  alias {
    name                   = "${aws_cloudfront_distribution.domain_distribution.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.domain_distribution.hosted_zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "root-aaaa" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name    = "${var.domain}"
  type    = "AAAA"
  alias {
    name                   = "${aws_cloudfront_distribution.domain_distribution.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.domain_distribution.hosted_zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www-a" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name    = "www.${var.domain}"
  type    = "A"
  alias {
    name                   = "${aws_cloudfront_distribution.domain_distribution.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.domain_distribution.hosted_zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www-aaaa" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name    = "www.${var.domain}"
  type    = "AAAA"
  alias {
    name                   = "${aws_cloudfront_distribution.domain_distribution.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.domain_distribution.hosted_zone_id}"
    evaluate_target_health = true
  }
}