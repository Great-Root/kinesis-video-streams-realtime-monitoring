output "ec2_instance_id" {
  description = "배포된 EC2 인스턴스 ID"
  value       = aws_instance.video_streaming_ec2.id
}

output "ec2_public_ip" {
  description = "배포된 EC2의 공용 IP 주소"
  value       = aws_instance.video_streaming_ec2.public_ip
}

output "ec2_private_ip" {
  description = "배포된 EC2의 프라이빗 IP 주소"
  value       = aws_instance.video_streaming_ec2.private_ip
}
