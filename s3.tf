resource "aws_s3_bucket" "main" {
  bucket        = "wiz-backup-${random_string.main.result}"
  force_destroy = true
}

## Per requirements, make bucket public
resource "aws_s3_bucket_public_access_block" "main" {
  bucket                  = aws_s3_bucket.main.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.allow_access_from_another_account.json

  depends_on = [aws_s3_bucket_public_access_block.main]
}

data "aws_iam_policy_document" "allow_access_from_another_account" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.main.arn,
      "${aws_s3_bucket.main.arn}/*",
    ]
  }
}
