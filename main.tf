provider "aws" {
  region = "us-east-2"
}

locals {
  app_name = "mid-test-tommy-serverless"
}

module "s3" {
  source      = "./modules/s3"
  bucket_name = local.app_name
}

module "cloudfront" {
  source                 = "./modules/cloudfront"
  s3_bucket              = module.s3.aws_s3_bucket
  origin_id              = module.s3.origin_id
  origin_access_identity = module.s3.origin_access_identity
}

output "origin_id" {
  value = module.s3.origin_id
}

output "origin_access_identity" {
  value = module.s3.origin_access_identity
}
