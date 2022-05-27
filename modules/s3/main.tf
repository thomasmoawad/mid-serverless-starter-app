resource "aws_cloudfront_origin_access_identity" "access_identity" {
  comment = "Tommy"
}


# "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.access_identity.id}"

resource "aws_s3_bucket" "basic-s3-bucket" {
  bucket        = var.bucket_name
  force_destroy = true
  policy        = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
               "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.access_identity.id}"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${var.bucket_name}/*",
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "true"
                }
            }
        }
    ]
} 
EOF
}

resource "aws_s3_bucket_acl" "dashboard_s3_bucket_acl" {
  bucket = aws_s3_bucket.basic-s3-bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.basic-s3-bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

output "aws_s3_bucket" {
  value = aws_s3_bucket.basic-s3-bucket
}

output "origin_id" {
  value = aws_cloudfront_origin_access_identity.access_identity.id
}

output "origin_access_identity" {
  value = aws_cloudfront_origin_access_identity.access_identity.cloudfront_access_identity_path
}

locals {
  upload_s3_path = "src/s3"
}
# First, zip the files. This is used to get a hash of the directory
data "archive_file" "s3_files" {
  type        = "zip"
  source_dir  = local.upload_s3_path
  output_path = "dist/uploaded_s3_files.zip"
}

# Next, use local-exec to upload the files
resource "null_resource" "upload_s3_files" {
  # Use the directory hash to determine if any changes have been made
  triggers = {
    src_hash = "${data.archive_file.s3_files.output_sha}"
  }
  provisioner "local-exec" {
    command = "aws s3 sync ${local.upload_s3_path} s3://${aws_s3_bucket.basic-s3-bucket.id}/ --delete"
  }
}
