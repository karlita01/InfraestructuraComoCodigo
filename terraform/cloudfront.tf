resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for CloudFront to access S3 buckets"
}

resource "aws_cloudfront_distribution" "frontend_cdn" {
  origin {
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id   = "frontendS3"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  origin {
    domain_name = aws_s3_bucket.frontend_backup.bucket_regional_domain_name
    origin_id   = "frontendS3Backup"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
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
  viewer_protocol_policy     = "redirect-to-https"
  allowed_methods            = ["GET", "HEAD"]
  cached_methods             = ["GET", "HEAD"]
  target_origin_id           = "origin-group-1"
  response_headers_policy_id = aws_cloudfront_response_headers_policy.default_security.id

    lambda_function_association {
    event_type   = "viewer-request"
    lambda_arn   = module.lambda_redirect.lambda_arn
    include_body = false
  }

  forwarded_values {
  query_string = true
  cookies {
    forward = "all"
  }
}
}


restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["PE"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  depends_on = [aws_cloudfront_origin_access_identity.oai]
}

resource "aws_cloudfront_response_headers_policy" "default_security" {
  name = "default-security-policy"

  security_headers_config {
    xss_protection {
      override   = true
      protection = true
      mode_block = true
    }
    frame_options {
      override      = true
      frame_option  = "DENY"
    }
    referrer_policy {
      override        = true
      referrer_policy = "no-referrer"
    }
    content_type_options {
      override = true
    }
    strict_transport_security {
      override                 = true
      include_subdomains       = true
      preload                  = true
      access_control_max_age_sec = 63072000
    }
  }
}