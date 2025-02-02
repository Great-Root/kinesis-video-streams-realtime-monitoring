# 최신 Ubuntu 20.04 AMI ID 가져오기
data "aws_ssm_parameter" "default_ami" {
  name = "/aws/service/canonical/ubuntu/server/20.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

# EC2 인스턴스 생성
resource "aws_instance" "video_streaming_ec2" {
  ami                    = data.aws_ssm_parameter.default_ami.value
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.video_streaming_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.video_streaming_profile.name
  key_name               = aws_key_pair.ssh_key.key_name
  user_data              = templatefile("${path.module}/user_data.sh", { 
    kinesis_stream_name = var.kinesis_stream_name,
    region              = var.region
    })

  tags = {
    Name = "${var.project_name}-${var.environment}-video-streaming-ec2"
  }
}

# Elastic IP 할당
resource "aws_eip" "compute_eip" {
  instance = aws_instance.video_streaming_ec2.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-video-streaming-eip"
  }
}
