# terraform/main.tf
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.84.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment = terraform.workspace
      Project     = var.project_name
    }
  }
}


# ==============================
# 🌐 네트워크 인프라 모듈
# ==============================
module "network_infrastructure" {
  source         = "./modules/network-infrastructure"
  project_name   = var.project_name
  environment    = terraform.workspace
  network_config = var.network_config
}

# ==============================
# 🎥 비디오 처리 (Kinesis + Rekognition)
# ==============================
module "video_processing" {
  source              = "./modules/video-processing"
  project_name        = var.project_name
  region              = var.region
  environment         = terraform.workspace

  sample_streaming    = var.sample_streaming
  ssh_cidr_blocks     = var.ssh_allowed_cidrs
  vpc_id              = module.network_infrastructure.vpc_id
  subnet_id           = module.network_infrastructure.public_subnet_ids["public1"]

  enable_rekognition  = var.enable_rekognition
  kvs_retention_hours = var.kvs_retention_hours
  face_match_threshold = var.face_match_threshold
}

# ==============================
# 📩 이벤트 메시징 (WebSocket + Kinesis)
# ==============================
module "event_messaging" {
  source              = "./modules/event-messaging"
  project_name        = var.project_name
  region              = var.region
  environment         = terraform.workspace
  kinesis_stream_arn  = module.video_processing.kinesis_data_stream_arn

  cognito_user_pool_id = module.frontend_hosting.user_pool_id
  cognito_client_id    = module.frontend_hosting.user_pool_client_id
}


# ==============================
# 🌍 프론트엔드 호스팅 모듈
# ==============================
module "frontend_hosting" {
  source                  = "./modules/frontend-hosting"
  project_name            = var.project_name
  region                  = var.region
  environment             = terraform.workspace
  price_class             = var.price_class

  enable_waf              = var.enable_waf
  allowed_ip_ranges       = var.waf_allowed_cidrs

  enable_geo_restriction  = var.enable_geo_restriction
  geo_restriction_type    = var.geo_restriction_type
  geo_restriction_locations = var.geo_restriction_locations
  
  websocket_api_arn       = module.event_messaging.websocket_api_arn
}