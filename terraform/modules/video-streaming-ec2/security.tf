# 보안 그룹 설정
resource "aws_security_group" "video_streaming_sg" {
  vpc_id = var.vpc_id

  # SSH 접근 (변수로 지정한 CIDR에서만 허용)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
    description = "SSH Access"
  }
}
