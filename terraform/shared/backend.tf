terraform {
  backend "s3" {
    bucket         = "s3-dependency-terraform-state-all-apse6"
    key            = "shared/terraform.tfstate"
    dynamodb_table = "dynamodb-dependency-terraform-state-all-apse6"
    region         = "ap-southeast-6"
  }
}