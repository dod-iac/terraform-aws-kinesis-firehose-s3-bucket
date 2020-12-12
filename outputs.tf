output "kinesis_firehose_delivery_stream_arn" {
  description = "The ARN of the Kinesis Data Firehose Delivery Stream"
  value       = aws_kinesis_firehose_delivery_stream.main.arn
}

output "kinesis_firehose_delivery_stream_name" {
  description = "The name of the Kinesis Data Firehose Delivery Stream"
  value       = aws_kinesis_firehose_delivery_stream.main.name
}
