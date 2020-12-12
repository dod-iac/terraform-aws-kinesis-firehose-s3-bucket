variable "cloudwatch_logging_enabled" {
  type        = bool
  description = "Enables or disables the logging to Cloudwatch Logs."
  default     = false
}

variable "cloudwatch_log_group_name" {
  type        = string
  description = "The CloudWatch Logs group name for logging.  Defaults to \"/aws/kinesisfirehose/[NAME]\""
  default     = ""
}

variable "cloudwatch_log_stream_name" {
  type        = string
  description = "The CloudWatch Logs stream name for logging."
  default     = "S3Delivery"
}

variable "kinesis_role_name" {
  type        = string
  description = "The name of the AWS IAM Role for reading records from the source AWS Kinesis Stream."
}

variable "kinesis_role_policy_document" {
  type        = string
  description = "The contents of the IAM policy attached to the IAM role used by the Kinesis Data Firehose Delivery Stream to read records from the source AWS Kinesis Stream.  If not defined, then creates a default policy."
  default     = ""
}

variable "kinesis_role_policy_name" {
  type        = string
  description = "The name of the IAM policy attached to the IAM Role used by the Kinesis Data Firehose Delivery Stream to read records from the source AWS Kinesis Stream.  If not defined, then uses the value of the \"kinesis_role_name\"."
  default     = ""
}

variable "kinesis_stream_arn" {
  type        = string
  description = "The AWS Kinesis Stream used as the source of the AWS Kinesis Data Firehose Delivery Stream."
}

variable "name" {
  type        = string
  description = "A name to identify the AWS Kinesis Data Firehose Delivery Stream. This is unique to the AWS account and region the stream is created in."
}

variable "s3_buffer_size" {
  type        = number
  description = "Buffer incoming data to the specified size, in MBs, before delivering it to the destination"
  default     = 5
}

variable "s3_buffer_interval" {
  type        = number
  description = "Buffer incoming data for the specified period of time, in seconds, before delivering it to the destination."
  default     = 300
}

variable "s3_bucket_arn" {
  type        = string
  description = "The ARN of the AWS S3 Bucket that receives the records."
}

variable "s3_compression_format" {
  type        = string
  description = "The compression format. Options: UNCOMPRESSED, GZIP, ZIP, and Snappy."
  default     = "UNCOMPRESSED"
}

variable "s3_error_output_prefix" {
  type        = string
  description = "Prefix added to failed records before writing them to S3. This prefix appears immediately following the bucket name."
  default     = ""
}

variable "s3_kms_key_arn" {
  type        = string
  description = "The ARN for the customer-managed KMS key to use for encrypt objects at rest in the AWS S3 Bucket."
  default     = ""
}

variable "s3_prefix" {
  type        = string
  description = "An extra S3 Key prefix prepended before the time format prefix of records delivered to the AWS S3 Bucket."
  default     = ""
}

variable "s3_role_name" {
  type        = string
  description = "The name of the AWS IAM Role for delivering files to the destination AWS S3 Bucket."
}

variable "s3_role_policy_document" {
  type        = string
  description = "The contents of the IAM policy attached to the IAM role used by the Kinesis Data Firehose Delivery Stream for delivering data to the AWS S3 Bucket.  If not defined, then creates the policy based on allowed actions."
  default     = ""
}

variable "s3_role_policy_name" {
  type        = string
  description = "The name of the IAM policy attached to the IAM Role used by the Kinesis Data Firehose Delivery Stream.  If not defined, then uses the value of the \"s3_role_name\"."
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the AWS Kinesis Data Firehose Delivery Stream."
  default     = {}
}
