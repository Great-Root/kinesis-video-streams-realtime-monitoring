# ==============================
# 🌍 네트워크 인프라 출력값
# ==============================
output "vpc_id" {
  description = "VPC ID"
  value       = module.network_infrastructure.vpc_id
}

output "public_subnet_ids" {
  description = "공용 서브넷 ID 목록"
  value       = module.network_infrastructure.public_subnet_ids
}

output "private_subnet_ids" {
  description = "사설 서브넷 ID 목록"
  value       = module.network_infrastructure.private_subnet_ids
}

# ==============================
# 🔐 Cognito 인증 정보
# ==============================
output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.frontend_hosting.user_pool_id
}

output "cognito_user_pool_client_id" {
  description = "Cognito User Pool Web Client ID"
  value       = module.frontend_hosting.user_pool_client_id
}

output "cognito_identity_pool_id" {
  description = "Cognito Identity Pool ID"
  value       = module.frontend_hosting.identity_pool_id
}

# ==============================
# 🎥 Kinesis Video Stream
# ==============================
output "kinesis_video_stream_arn" {
  description = "Kinesis Video Stream ARN"
  value       = module.video_processing.kinesis_video_stream_arn
}

output "kinesis_data_stream_arn" {
  description = "Kinesis Data Stream ARN"
  value       = module.video_processing.kinesis_data_stream_arn 
}

# ==============================
# 🧠 Rekognition 설정
# ==============================
output "rekognition_collection_id" {
  description = "Rekognition 얼굴 인식 Collection ID"
  value       = module.video_processing.rekognition_collection_id
}

# ==============================
# 🖥️ EC2 (Video Streaming Node)
# ==============================
output "video_streaming_ec2_public_ip" {
  description = "Video Streaming EC2 퍼블릭 IP"
  value       = var.sample_streaming ? module.video_processing.ec2_public_ip : null
}

output "video_streaming_ec2_ssh_command" {
  description = "Video Streaming EC2 SSH 접속 명령어"
  value       = var.sample_streaming ? "ssh -i ~/.ssh/${module.video_processing.ssh_key_name}.pem ubuntu@${module.video_processing.ec2_public_ip}" : null
}

# ==============================
# 🚀 Frontend Hosting (CloudFront + S3)
# ==============================
output "website_url" {
  description = "정적 웹사이트 URL"
  value       = "https://${module.frontend_hosting.cloudfront_domain_name}"
}

output "frontend_s3_bucket_name" {
  description = "Frontend 호스팅 S3 버킷 이름"
  value       = module.frontend_hosting.s3_bucket_name
}

output "start_rekognition_stream_processor" {
  value = "aws rekognition start-stream-processor --name ${module.video_processing.rekognition_stream_processor_name} --region ${var.region}"
}
output "stop_rekognition_stream_processor" {
  value = "aws rekognition stop-stream-processor --name ${module.video_processing.rekognition_stream_processor_name} --region ${var.region}"
}
output "describe_rekognition_stream_processor" {
  value = "aws rekognition describe-stream-processor --name ${module.video_processing.rekognition_stream_processor_name} --region ${var.region}"
}


output "rekognition_delete_collection_command" {
  description = "Delete the Rekognition collection"
  value       = "aws rekognition delete-collection --collection-id ${module.video_processing.rekognition_collection_id} --region ${var.region}"
}

output "rekognition_list_collections_command" {
  description = "List all Rekognition collections"
  value       = "aws rekognition list-collections --region ${var.region}"
}

output "rekognition_describe_collection_command" {
  description = "Describe the Rekognition collection"
  value       = "aws rekognition describe-collection --collection-id ${module.video_processing.rekognition_collection_id} --region ${var.region}"
}

output "rekognition_create_collection_command" {
  description = "Create a Rekognition collection"
  value       = "aws rekognition create-collection --collection-id ${module.video_processing.rekognition_collection_id} --region ${var.region}"
}

output "kvs_gstreamer_streaming_command" {
  description = "KVS GStreamer sample streaming command"
  value       = "while true; do ./kvs_gstreamer_sample ${module.video_processing.rekognition_stream_processor_name} ~/sample.mp4 && sleep 10s; done"
}
