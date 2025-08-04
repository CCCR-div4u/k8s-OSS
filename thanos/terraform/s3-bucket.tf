# Thanos 메트릭 저장용 S3 버킷
resource "random_string" "thanos_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "thanos_metrics" {
  bucket = "thanos-metrics-${random_string.thanos_suffix.result}"
}

resource "aws_s3_bucket_versioning" "thanos_metrics" {
  bucket = aws_s3_bucket.thanos_metrics.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "thanos_metrics" {
  bucket = aws_s3_bucket.thanos_metrics.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "thanos_metrics" {
  bucket = aws_s3_bucket.thanos_metrics.id

  rule {
    id     = "thanos_metrics_lifecycle"
    status = "Enabled"

    expiration {
      days = 2555  # 7년 보존
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }
  }
}

# 출력
output "thanos_s3_bucket" {
  description = "Thanos 메트릭 저장용 S3 버킷 이름"
  value       = aws_s3_bucket.thanos_metrics.bucket
}

output "thanos_s3_bucket_region" {
  description = "S3 버킷 리전"
  value       = aws_s3_bucket.thanos_metrics.region
}