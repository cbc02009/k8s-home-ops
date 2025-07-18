terraform {
  required_providers {
    minio = {
      source = "aminueza/minio"
      version = "3.5.4"
    }
  }
}

module "onepassword" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = var.vault
  item   = var.bucket_name
}

resource "minio_s3_bucket" "bucket" {
  bucket = var.bucket_name
  acl    = "private"
}

resource "minio_s3_bucket_versioning" "bucket" {
  depends_on = [minio_s3_bucket.bucket]
  bucket     = minio_s3_bucket.bucket.bucket
  versioning_configuration {
    status = "Enabled"
  }
  count = var.versioning ? 1 : 0
}

resource "minio_iam_user" "user" {
  name          = var.user_name != null ? var.user_name : var.bucket_name
  force_destroy = true
  secret        = module.onepassword.fields[var.user_secret_item]
}

resource "minio_iam_policy" "rw_policy" {
  name = "${var.bucket_name}-rw"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "arn:aws:s3:::${minio_s3_bucket.bucket.bucket}",
                "arn:aws:s3:::${minio_s3_bucket.bucket.bucket}/*"
            ],
            "Sid": ""
        }
    ]
}
EOF
}

resource "minio_iam_user_policy_attachment" "user_rw" {
  user_name   = minio_iam_user.user.id
  policy_name = minio_iam_policy.rw_policy.id
}
