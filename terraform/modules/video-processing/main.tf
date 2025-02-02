# 자동 생성될 리소스 이름
locals {
  collection_id     = "${var.project_name}-${var.environment}-rekognition-collection"
  video_stream_name = "${var.project_name}-${var.environment}-kvs-stream"
  data_stream_name  = "${var.project_name}-${var.environment}-kinesis-data-stream"
}

##########################
# Rekognition 관련 리소스
##########################

# Rekognition Collection 생성
resource "aws_rekognition_collection" "face_collection" {
  count         = var.enable_rekognition ? 1 : 0
  collection_id = local.collection_id 
}

##############################
# Kinesis Video Streams & Data Streams 관련 리소스
##############################

# Kinesis Video Stream 생성
resource "aws_kinesis_video_stream" "video_stream" {
  name                   = local.video_stream_name
  data_retention_in_hours = var.kvs_retention_hours
}

# Kinesis Data Stream 생성
resource "aws_kinesis_stream" "data_stream" {
  name        = local.data_stream_name
  shard_count = 1
}

#############################################
# Rekognition Stream Processor 관련 리소스
#############################################

# IAM Role for Rekognition Stream Processor
resource "aws_iam_role" "stream_processor_role" {
  count = var.enable_rekognition ? 1 : 0

  name = "${var.project_name}-${var.environment}-rekognition-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "rekognition.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy Attachments
resource "aws_iam_policy_attachment" "stream_processor_role_policy" {
  count = var.enable_rekognition ? 1 : 0

  name       = "${var.project_name}-${var.environment}-rekognition-policy-attachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisFullAccess"
  roles      = [aws_iam_role.stream_processor_role[0].name]
}

resource "aws_iam_policy_attachment" "stream_processor_service_role_policy" {
  count = var.enable_rekognition ? 1 : 0

  name       = "${var.project_name}-${var.environment}-rekognition-service-role-attachment"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRekognitionServiceRole"
  roles      = [aws_iam_role.stream_processor_role[0].name]
}

# Rekognition Stream Processor 생성
resource "aws_rekognition_stream_processor" "stream_processor" {
  count = var.enable_rekognition ? 1 : 0

  name     = "${var.project_name}-${var.environment}-rekognition-processor"
  role_arn = aws_iam_role.stream_processor_role[0].arn

  input {
    kinesis_video_stream {
      arn = aws_kinesis_video_stream.video_stream.arn
    }
  }

  output {
    kinesis_data_stream {
      arn = aws_kinesis_stream.data_stream.arn
    }
  }

  settings {
    face_search {
      collection_id        = aws_rekognition_collection.face_collection[0].id
      face_match_threshold = var.face_match_threshold
    }
  }

  data_sharing_preference {
    opt_in = false
  }
}

##################################
# 샘플 스트리밍 EC2 배포 (옵션)
##################################
module "video_streaming_ec2" {
  count = var.sample_streaming ? 1 : 0

  source              = "../video-streaming-ec2"
  project_name        = var.project_name
  region              = var.region
  environment         = var.environment
  vpc_id              = var.vpc_id
  subnet_id           = var.subnet_id
  kinesis_stream_name = local.video_stream_name
  ssh_cidr_blocks     = var.ssh_cidr_blocks
}

##################################
# S3 버킷 및 Rekognition IndexFaces 관련 리소스
##################################

# S3 버킷 생성 (faces 이미지 저장용)
resource "aws_s3_bucket" "faces_bucket" {
  bucket = "${var.project_name}-${var.environment}-faces"
}

# faces 폴더 내 이미지들을 S3에 업로드
resource "aws_s3_object" "face_images" {
  for_each = fileset("${path.module}/faces", "*")
  bucket   = aws_s3_bucket.faces_bucket.bucket
  key      = "faces/${each.value}"
  source   = "${path.module}/faces/${each.value}"
  etag     = filemd5("${path.module}/faces/${each.value}")
}

# S3 버킷 정책: Rekognition이 S3 객체를 읽을 수 있도록 허용
resource "aws_s3_bucket_policy" "faces_bucket_policy" {
  bucket = aws_s3_bucket.faces_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "AllowRekognitionAccess",
        Effect: "Allow",
        Principal: {
          Service: "rekognition.amazonaws.com"
        },
        Action: "s3:GetObject",
        Resource: "${aws_s3_bucket.faces_bucket.arn}/*"
      }
    ]
  })
}

# 각 이미지에 대해 IndexFaces 명령어 실행 (S3에 업로드된 이미지들을 Rekognition 컬렉션에 인덱싱)
resource "null_resource" "index_faces" {
  for_each = fileset("${path.module}/faces", "*")

  provisioner "local-exec" {
    command = <<EOT
      aws rekognition index-faces \
        --region ${var.region} \
        --collection-id ${aws_rekognition_collection.face_collection[0].id} \
        --image "S3Object={Bucket=${aws_s3_bucket.faces_bucket.bucket},Name=faces/${each.value}}" \
        --external-image-id ${each.value} \
        --max-faces 1
    EOT
  }

  triggers = {
    image_md5 = filemd5("${path.module}/faces/${each.value}")
  }

  depends_on = [
    aws_s3_object.face_images,
    aws_rekognition_collection.face_collection
  ]
}
