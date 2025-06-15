resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "index.html"
  source       = "../frontend/index.html"
  content_type = "text/html"
}

resource "aws_s3_object" "error_html" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "error.html"
  source       = "../frontend/error.html"
  content_type = "text/html"
}

resource "local_file" "config_js" {
  filename = "${path.module}/../frontend/config.js"
  content  = <<EOT
const base = "${aws_api_gateway_stage.prod.invoke_url}";
EOT
}

resource "aws_s3_object" "config_js" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "config.js"
  source       = local_file.config_js.filename 
  content_type = "application/javascript"
  depends_on = [local_file.config_js]
}
resource "aws_s3_bucket" "frontend" {
  bucket         = "minimarket-frontend-charlie"
  force_destroy  = true
}

resource "aws_kms_key" "frontend_key" {
  description         = "KMS key for S3 frontend encryption"
  enable_key_rotation = true
}

resource "aws_s3_bucket_versioning" "frontend_versioning" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend_sse" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.frontend_key.arn
    }
  }
}


resource "aws_s3_bucket_public_access_block" "frontend_block" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = false
  block_public_policy     = false
  restrict_public_buckets = false
  ignore_public_acls      = false
}

resource "aws_s3_bucket_website_configuration" "frontend_website" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "allow_public_read" {
  bucket = aws_s3_bucket.frontend.id

  depends_on = [aws_s3_bucket_public_access_block.frontend_block]

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = ["s3:GetObject"],
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket" "frontend_backup" {
  bucket         = "minimarket-frontend-charlie-backup"
  force_destroy  = true
}

resource "aws_kms_key" "frontend_backup_key" {
  description         = "KMS key for S3 frontend backup encryption"
  enable_key_rotation = true
}

resource "aws_s3_bucket_versioning" "frontend_backup_versioning" {
  bucket = aws_s3_bucket.frontend_backup.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend_backup_sse" {
  bucket = aws_s3_bucket.frontend_backup.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.frontend_backup_key.arn
    }
  }
}

resource "aws_s3_bucket_website_configuration" "frontend_website_backup" {
  bucket = aws_s3_bucket.frontend_backup.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}
