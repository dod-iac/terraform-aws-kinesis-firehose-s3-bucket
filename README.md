## Usage

Creates a Kinesis Data Firehose Delivery Stream that retrieves records from a Kinesis Data Stream and delivers them to a S3 Bucket.

```hcl

module "kinesis_stream" {
  source = "dod-iac/kinesis-stream/aws"

  name = format("app-%s-%s", var.application, var.environment)
  tags = {
    Application = var.application
    Environment = var.environment
    Automation  = "Terraform"
  }
}

module "kinesis_firehose_s3_bucket" {
  source  = "dod-iac/kinesis-firehose-s3-bucket/aws"

  name = format("app-%s-firehose-%s", var.application, var.environment)

  kinesis_stream_arn = module.kinesis_stream.arn
  kinesis_role_name = format("app-%s-firehose-source-%s", var.application, var.environment)

  s3_bucket_arn = var.aws_s3_bucket_destination
  s3_role_name = format("app-%s-firehose-destination-%s", var.application, var.environment)

  tags = {
    Application = var.application
    Environment = var.environment
    Automation  = "Terraform"
  }
}
```

Creates a Kinesis Data Firehose Delivery Stream that retrieves records from an encrypted Kinesis Data Stream and delivers them to a S3 Bucket encrypted at-rest.

```hcl

module "kinesis_kms_key" {
  source = "dod-iac/kinesis-kms-key/aws"

  name = format("alias/app-%s-kinesis-%s", var.application, var.environment)
  description = format("A KMS key used to encrypt Kinesis stream records at rest for %s:%s.", var.application, var.environment)
  tags = {
    Application = var.application
    Environment = var.environment
    Automation  = "Terraform"
  }
}

module "kinesis_stream" {
  source = "dod-iac/kinesis-stream/aws"

  name = format("app-%s-%s", var.application, var.environment)
  kms_key_id = module.kinesis_kms_key.aws_kms_key_arn
  tags = {
    Application = var.application
    Environment = var.environment
    Automation  = "Terraform"
  }
}

module "kinesis_firehose_s3_kms_key" {
  source  = "dod-iac/s3-kms-key/aws"

  name = format("alias/app-%s-firehose-destination-s3-%s", var.application, var.environment)
  description = format(
    "A KMS key used by AWS Kinesis Data Firehose Delivery Stream to encrypt objects at rest in S3 for %s:%s",
    var.application,
    var.environment
  )

  # To avoid a circular dependency, format the role ARN rather than use
  # output from the following kinesis_firehose_s3_bucket module.
  principals = [format("arn:%s:iam::%s:role/app-%s-firehose-destination-s3-%s",
    data.aws_partition.current.partition,
    data.aws_caller_identity.current.account_id,
    var.application,
    var.environment
  )]

  tags = {
    Application = var.application
    Environment = var.environment
    Automation  = "Terraform"
  }

}

module "kinesis_firehose_s3_bucket" {
  source  = "dod-iac/kinesis-firehose-s3-bucket/aws"

  name = format("app-%s-firehose-%s", var.application, var.environment)

  kinesis_stream_arn = module.kinesis_stream.arn
  kinesis_role_name = format("app-%s-firehose-source-kinesis-%s", var.application, var.environment)

  s3_bucket_arn = var.aws_s3_bucket_destination
  s3_prefix = "data/"
  s3_role_name = format("app-%s-firehose-destination-s3-%s", var.application, var.environment)
  s3_kms_key_arn = module.kinesis_firehose_s3_kms_key.aws_kms_key_arn

  tags = {
    Application = var.application
    Environment = var.environment
    Automation  = "Terraform"
  }
}
```

## Terraform Version

Terraform 0.13. Pin module version to ~> 1.0.0 . Submit pull-requests to master branch.

Terraform 0.11 and 0.12 are not supported.

## License

This project constitutes a work of the United States Government and is not subject to domestic copyright protection under 17 USC § 105.  However, because the project utilizes code licensed from contributors and other third parties, it therefore is licensed under the MIT License.  See LICENSE file for more information.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12 |
| aws | >= 2.55.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 2.55.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cloudwatch\_log\_group\_name | The CloudWatch Logs group name for logging.  Defaults to "/aws/kinesisfirehose/[NAME]" | `string` | `""` | no |
| cloudwatch\_log\_stream\_name | The CloudWatch Logs stream name for logging. | `string` | `"S3Delivery"` | no |
| cloudwatch\_logging\_enabled | Enables or disables the logging to Cloudwatch Logs. | `bool` | `false` | no |
| kinesis\_role\_name | The name of the AWS IAM Role for reading records from the source AWS Kinesis Stream. | `string` | n/a | yes |
| kinesis\_role\_policy\_document | The contents of the IAM policy attached to the IAM role used by the Kinesis Data Firehose Delivery Stream to read records from the source AWS Kinesis Stream.  If not defined, then creates a default policy. | `string` | `""` | no |
| kinesis\_role\_policy\_name | The name of the IAM policy attached to the IAM Role used by the Kinesis Data Firehose Delivery Stream to read records from the source AWS Kinesis Stream.  If not defined, then uses the value of the "kinesis\_role\_name". | `string` | `""` | no |
| kinesis\_stream\_arn | The AWS Kinesis Stream used as the source of the AWS Kinesis Data Firehose Delivery Stream. | `string` | n/a | yes |
| name | A name to identify the AWS Kinesis Data Firehose Delivery Stream. This is unique to the AWS account and region the stream is created in. | `string` | n/a | yes |
| s3\_bucket\_arn | The ARN of the AWS S3 Bucket that receives the records. | `string` | n/a | yes |
| s3\_buffer\_interval | Buffer incoming data for the specified period of time, in seconds, before delivering it to the destination. | `number` | `300` | no |
| s3\_buffer\_size | Buffer incoming data to the specified size, in MBs, before delivering it to the destination | `number` | `5` | no |
| s3\_compression\_format | The compression format. Options: UNCOMPRESSED, GZIP, ZIP, and Snappy. | `string` | `"UNCOMPRESSED"` | no |
| s3\_error\_output\_prefix | Prefix added to failed records before writing them to S3. This prefix appears immediately following the bucket name. | `string` | `""` | no |
| s3\_kms\_key\_arn | The ARN for the customer-managed KMS key to use for encrypt objects at rest in the AWS S3 Bucket. | `string` | `""` | no |
| s3\_prefix | An extra S3 Key prefix prepended before the time format prefix of records delivered to the AWS S3 Bucket. | `string` | `""` | no |
| s3\_role\_name | The name of the AWS IAM Role for delivering files to the destination AWS S3 Bucket. | `string` | n/a | yes |
| s3\_role\_policy\_document | The contents of the IAM policy attached to the IAM role used by the Kinesis Data Firehose Delivery Stream for delivering data to the AWS S3 Bucket.  If not defined, then creates the policy based on allowed actions. | `string` | `""` | no |
| s3\_role\_policy\_name | The name of the IAM policy attached to the IAM Role used by the Kinesis Data Firehose Delivery Stream.  If not defined, then uses the value of the "s3\_role\_name". | `string` | `""` | no |
| tags | Tags applied to the AWS Kinesis Data Firehose Delivery Stream. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| kinesis\_firehose\_delivery\_stream\_arn | The ARN of the Kinesis Data Firehose Delivery Stream |
| kinesis\_firehose\_delivery\_stream\_name | The name of the Kinesis Data Firehose Delivery Stream |

