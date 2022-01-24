/**
 * ## Usage
 *
 * Creates a Kinesis Data Firehose Delivery Stream that retrieves records from a Kinesis Data Stream and delivers them to a S3 Bucket.
 *
 * ```hcl
 *
 * module "kinesis_stream" {
 *   source = "dod-iac/kinesis-stream/aws"
 *
 *   name = format("app-%s-%s", var.application, var.environment)
 *   tags = {
 *     Application = var.application
 *     Environment = var.environment
 *     Automation  = "Terraform"
 *   }
 * }
 *
 * module "kinesis_firehose_s3_bucket" {
 *   source  = "dod-iac/kinesis-firehose-s3-bucket/aws"
 *
 *   name = format("app-%s-firehose-%s", var.application, var.environment)
 *
 *   kinesis_stream_arn = module.kinesis_stream.arn
 *   kinesis_role_name = format("app-%s-firehose-source-%s", var.application, var.environment)
 *
 *   s3_bucket_arn = var.aws_s3_bucket_destination
 *   s3_role_name = format("app-%s-firehose-destination-%s", var.application, var.environment)
 *
 *   tags = {
 *     Application = var.application
 *     Environment = var.environment
 *     Automation  = "Terraform"
 *   }
 * }
 * ```
 *
 * Creates a Kinesis Data Firehose Delivery Stream that retrieves records from an encrypted Kinesis Data Stream and delivers them to a S3 Bucket encrypted at-rest.
 *
 * ```hcl
 *
 * module "kinesis_kms_key" {
 *   source = "dod-iac/kinesis-kms-key/aws"
 *
 *   name = format("alias/app-%s-kinesis-%s", var.application, var.environment)
 *   description = format("A KMS key used to encrypt Kinesis stream records at rest for %s:%s.", var.application, var.environment)
 *   tags = {
 *     Application = var.application
 *     Environment = var.environment
 *     Automation  = "Terraform"
 *   }
 * }
 *
 * module "kinesis_stream" {
 *   source = "dod-iac/kinesis-stream/aws"
 *
 *   name = format("app-%s-%s", var.application, var.environment)
 *   kms_key_id = module.kinesis_kms_key.aws_kms_key_arn
 *   tags = {
 *     Application = var.application
 *     Environment = var.environment
 *     Automation  = "Terraform"
 *   }
 * }
 *
 * module "kinesis_firehose_s3_kms_key" {
 *   source  = "dod-iac/s3-kms-key/aws"
 *
 *   name = format("alias/app-%s-firehose-destination-s3-%s", var.application, var.environment)
 *   description = format(
 *     "A KMS key used by AWS Kinesis Data Firehose Delivery Stream to encrypt objects at rest in S3 for %s:%s",
 *     var.application,
 *     var.environment
 *   )
 *
 *   # To avoid a circular dependency, format the role ARN rather than use
 *   # output from the following kinesis_firehose_s3_bucket module.
 *   principals = [format("arn:%s:iam::%s:role/app-%s-firehose-destination-s3-%s",
 *     data.aws_partition.current.partition,
 *     data.aws_caller_identity.current.account_id,
 *     var.application,
 *     var.environment
 *   )]
 *
 *   tags = {
 *     Application = var.application
 *     Environment = var.environment
 *     Automation  = "Terraform"
 *   }
 *
 * }
 *
 * module "kinesis_firehose_s3_bucket" {
 *   source  = "dod-iac/kinesis-firehose-s3-bucket/aws"
 *
 *   name = format("app-%s-firehose-%s", var.application, var.environment)
 *
 *   kinesis_stream_arn = module.kinesis_stream.arn
 *   kinesis_role_name = format("app-%s-firehose-source-kinesis-%s", var.application, var.environment)
 *
 *   s3_bucket_arn = var.aws_s3_bucket_destination
 *   s3_prefix = "data/"
 *   s3_role_name = format("app-%s-firehose-destination-s3-%s", var.application, var.environment)
 *   s3_kms_key_arn = module.kinesis_firehose_s3_kms_key.aws_kms_key_arn
 *
 *   tags = {
 *     Application = var.application
 *     Environment = var.environment
 *     Automation  = "Terraform"
 *   }
 * }
* 
*  resource "aws_cloudwatch_log_group" "fh-to-s3-delivery-log-group" {
*     name = format("/aws/kinesisfirehose/%s-%s-fh-%s", var.project, var.application, var.environment)
*  }
* 
*  resource "aws_cloudwatch_log_stream" "fh-to-s3-delivery-log-stream" {
*     name           = "S3Delivery"
*     log_group_name = aws_cloudwatch_log_group.fh-to-s3-delivery-log-group.name
*  }
 * ```
 *
 * ## Terraform Version
 *
 * Terraform 0.13. Pin module version to ~> 1.0.0 . Submit pull-requests to master branch.
 *
 * Terraform 0.11 and 0.12 are not supported.
 *
 * ## License
 *
 * This project constitutes a work of the United States Government and is not subject to domestic copyright protection under 17 USC § 105.  However, because the project utilizes code licensed from contributors and other third parties, it therefore is licensed under the MIT License.  See LICENSE file for more information.
 */

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_partition" "current" {}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "firehose.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "kinesis_role" {
  name               = var.kinesis_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags               = var.tags
}

data "aws_iam_policy_document" "kinesis_role" {

  statement {
    sid = "AllowReadStream"
    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetRecords",
      "kinesis:GetShardIterator",
      "kinesis:ListShards"
    ]
    effect = "Allow"
    resources = [
      var.kinesis_stream_arn
    ]
  }

}

resource "aws_iam_policy" "kinesis_role" {
  name   = length(var.kinesis_role_policy_name) > 0 ? var.kinesis_role_policy_name : var.kinesis_role_name
  path   = "/"
  policy = length(var.kinesis_role_policy_document) > 0 ? var.kinesis_role_policy_document : data.aws_iam_policy_document.kinesis_role.json
}

resource "aws_iam_role_policy_attachment" "kinesis_role" {
  role       = aws_iam_role.kinesis_role.name
  policy_arn = aws_iam_policy.kinesis_role.arn
}

resource "aws_iam_role" "s3_role" {
  name               = var.s3_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags               = var.tags
}

data "aws_iam_policy_document" "s3_role" {

  statement {
    sid = "AllowBucketSync"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]
    effect = "Allow"
    resources = [
      var.s3_bucket_arn,
      format("%s/*", var.s3_bucket_arn)
    ]
  }

  statement {
    sid = "AllowPutLogEvents"
    actions = [
      "logs:PutLogEvents"
    ]
    effect = var.cloudwatch_logging_enabled ? "Allow" : "Deny"
    resources = var.cloudwatch_logging_enabled ? [format(
      "arn:%s:logs:%s:%s:log-group:%s:log-stream:%s",
      data.aws_partition.current.partition,
      data.aws_region.current.name,
      data.aws_caller_identity.current.account_id,
      length(var.cloudwatch_log_group_name) > 0 ? var.cloudwatch_log_group_name : format("/aws/kinesisfirehose/%s", var.name),
      var.cloudwatch_log_stream_name
    )] : ["*"]
  }

}

resource "aws_iam_policy" "s3_role" {
  name   = length(var.s3_role_policy_name) > 0 ? var.s3_role_policy_name : var.s3_role_name
  path   = "/"
  policy = length(var.s3_role_policy_document) > 0 ? var.s3_role_policy_document : data.aws_iam_policy_document.s3_role.json
}

resource "aws_iam_role_policy_attachment" "s3_role" {
  role       = aws_iam_role.s3_role.name
  policy_arn = aws_iam_policy.s3_role.arn
}

resource "aws_kinesis_firehose_delivery_stream" "main" {
  name        = var.name
  destination = "extended_s3"
  tags        = var.tags

  kinesis_source_configuration {
    kinesis_stream_arn = var.kinesis_stream_arn
    role_arn           = aws_iam_role.kinesis_role.arn
  }

  extended_s3_configuration {
    bucket_arn          = var.s3_bucket_arn
    buffer_size         = var.s3_buffer_size
    buffer_interval     = var.s3_buffer_interval
    compression_format  = var.s3_compression_format
    error_output_prefix = var.s3_error_output_prefix
    role_arn            = aws_iam_role.s3_role.arn
    prefix              = var.s3_prefix
    kms_key_arn         = length(var.s3_kms_key_arn) > 0 ? var.s3_kms_key_arn : null
    s3_backup_mode      = "Disabled"

    cloudwatch_logging_options {
      enabled         = var.cloudwatch_logging_enabled
      log_group_name  = length(var.cloudwatch_log_group_name) > 0 ? var.cloudwatch_log_group_name : format("/aws/kinesisfirehose/%s", var.name)
      log_stream_name = var.cloudwatch_log_stream_name
    }

    processing_configuration {
      enabled = false
    }
  }
}
