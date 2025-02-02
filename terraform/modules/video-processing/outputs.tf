output "rekognition_collection_id" {
  description = "Rekognition Collection ID"
  value       = var.enable_rekognition ? local.collection_id : null
}

output "kinesis_video_stream_arn" {
  description = "Kinesis Video Stream ARN"
  value       = aws_kinesis_video_stream.video_stream.arn
}

output "kinesis_data_stream_arn" {
  description = "Kinesis Data Stream ARN"
  value       = aws_kinesis_stream.data_stream.arn
}

output "rekognition_stream_processor_name" {
  description = "Rekognition Stream Processor 이름"
  value       = var.enable_rekognition ? aws_rekognition_stream_processor.stream_processor[0].name : null
}