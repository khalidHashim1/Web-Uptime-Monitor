terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# -----------------------------
# Unique suffix for S3 buckets
# -----------------------------
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# -----------------------------
# S3 Buckets
# -----------------------------
resource "aws_s3_bucket" "code_bucket" {
  bucket = "uptime-monitor-code-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket" "artifact_bucket" {
  bucket = "uptime-monitor-artifacts-${random_id.bucket_suffix.hex}"
}

# -----------------------------
# Archive Canary Code (auto zip)
# -----------------------------
data "archive_file" "canary_zip" {
  type        = "zip"
  source_file = "${path.module}/canary/index.js"
  output_path = "${path.module}/canary.zip"
}

# -----------------------------
# Upload ZIP to S3
# -----------------------------
#resource "aws_s3_object" "canary_zip" {
  #bucket = aws_s3_bucket.code_bucket.id
  #key    = "canary.zip"
 # source = data.archive_file.canary_zip.output_path
#}

resource "aws_s3_object" "canary_zip" {
  bucket = aws_s3_bucket.code_bucket.id
  key    = "canary.zip"
  source = data.archive_file.canary_zip.output_path

  etag = filemd5(data.archive_file.canary_zip.output_path)
  source_hash = data.archive_file.canary_zip.output_base64sha256
}

# -----------------------------
# IAM Role for Canary
# -----------------------------
resource "aws_iam_role" "canary_role" {
  name = "canary-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = [
          "lambda.amazonaws.com",
          "synthetics.amazonaws.com"
        ]
      }
    }]
  })
}

# Attach required policies
resource "aws_iam_role_policy_attachment" "canary_policy_1" {
  role       = aws_iam_role.canary_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchSyntheticsFullAccess"
}

resource "aws_iam_role_policy_attachment" "canary_policy_2" {
  role       = aws_iam_role.canary_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "canary_policy_3" {
  role       = aws_iam_role.canary_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# -----------------------------
# Synthetics Canary
# -----------------------------
resource "aws_synthetics_canary" "website_monitor" {
  name                 = "portfolio-uptime-monitor"
  artifact_s3_location = "s3://${aws_s3_bucket.artifact_bucket.id}/"
  execution_role_arn   = aws_iam_role.canary_role.arn
  handler              = "index.handler"
  runtime_version      = "syn-nodejs-puppeteer-13.1"

  s3_bucket = aws_s3_bucket.code_bucket.id
  s3_key    = aws_s3_object.canary_zip.key

  schedule {
    expression = "cron(0 6 * * ? *)"
  }

  depends_on = [aws_s3_object.canary_zip]
}

# -----------------------------
# SNS Alerts
# -----------------------------
resource "aws_sns_topic" "alerts" {
  name = "uptime-alerts"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "khalidhashim1422@gmail.com"
}

# -----------------------------
# CloudWatch Alarm
# -----------------------------
resource "aws_cloudwatch_metric_alarm" "uptime_alarm" {
  alarm_name          = "website-down-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "SuccessPercent"
  namespace           = "CloudWatchSynthetics"
  period              = 300
  statistic           = "Average"
  threshold           = 90

  dimensions = {
    CanaryName = aws_synthetics_canary.website_monitor.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}



resource "aws_iam_role_policy" "canary_cloudwatch_metrics" {
  name = "CanaryCloudWatchMetrics"
  role = aws_iam_role.canary_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics"
        ],
        Resource = "*"
      }
    ]
  })
}