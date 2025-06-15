resource "aws_cloudfront_distribution" "frontend_cdn" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.frontend_website.website_endpoint
    origin_id   = "frontendS3"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  origin {
    domain_name = aws_s3_bucket_website_configuration.frontend_website_backup.website_endpoint
    origin_id   = "frontendS3Backup"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  origin_group {
    origin_id = "origin-group-1"
    failover_criteria {
      status_codes = [403, 404, 500, 502, 503, 504]
    }
    member {
      origin_id = "frontendS3"
    }
    member {
      origin_id = "frontendS3Backup"
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "origin-group-1"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.default_security.id
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["PE"] # Código de Perú
    }
  }

    viewer_certificate {
    acm_certificate_arn            = "arn:aws:acm:us-east-2:612526786257:certificate/afaa74a6-8f1d-44f1-b7c4-65c4b55afacd"
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}

resource "aws_cloudfront_response_headers_policy" "default_security" {
  name = "default-security-policy"

  security_headers_config {
    xss_protection {
      override = true
      protection = true
      mode_block = true
    }
    frame_options {
      override = true
      frame_option = "DENY"
    }
    referrer_policy {
      override = true
      referrer_policy = "no-referrer"
    }
    content_type_options {
      override = true
    }
    strict_transport_security {
      override = true
      include_subdomains = true
      preload = true
      access_control_max_age_sec = 63072000
    }
  }
}