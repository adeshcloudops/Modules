# Configure AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# Create an S3 Bucket
resource "aws_s3_bucket" "cbz_bucket" {
  bucket = "cbz-frontend-project-bux"

  tags = {
    Name = "StaticWebsiteBucket"
    env  = "dev"
  }
}

# Enable Static Website Hosting
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.cbz_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Configure Public Access Block
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.cbz_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Set Bucket Policy for Public Read Access
resource "aws_s3_bucket_policy" "static_website_policy" {
  bucket = aws_s3_bucket.cbz_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.cbz_bucket.arn}/*"
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.example
  ]
}

# Output the S3 Website Endpoint
output "website_endpoint" {
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
  description = "The URL to access the static website"
}
