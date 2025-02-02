# IAM Role 생성
resource "aws_iam_role" "video_streaming_role" {
  name = "${var.project_name}-${var.environment}-video-streaming-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM Policy 생성
resource "aws_iam_policy" "video_streaming_policy" {
  name        = "${var.project_name}-${var.environment}-video-streaming-policy"
  description = "Policy for Kinesis Video Stream access"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "kinesisvideo:PutMedia",
        "kinesisvideo:DescribeStream",
        "kinesisvideo:GetDataEndpoint"
      ]
      Resource = "*"
    }]
  })
}

# IAM Role과 Policy 연결
resource "aws_iam_role_policy_attachment" "video_streaming_attach" {
  role       = aws_iam_role.video_streaming_role.name
  policy_arn = aws_iam_policy.video_streaming_policy.arn
}

# IAM Instance Profile 생성
resource "aws_iam_instance_profile" "video_streaming_profile" {
  name = "${var.project_name}-${var.environment}-video-streaming-profile"
  role = aws_iam_role.video_streaming_role.name
}
