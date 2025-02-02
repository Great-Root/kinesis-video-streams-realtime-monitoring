terraform {
  backend "s3" {
    bucket         = "kvs-groot-terraform-state-bucket"
    key            = "state/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "kvs-groot-terraform-locks"
    encrypt        = true
  }
}
