# SSH Key Pair 생성
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "${var.project_name}-${var.environment}-video-streaming-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# SSH Private Key를 로컬 파일로 저장
resource "local_file" "ssh_private_key" {
  filename = "${path.root}/.ssh/${var.project_name}-${var.environment}-video-streaming-key.pem"
  content  = tls_private_key.ssh_key.private_key_pem
  file_permission = "0600"
}
