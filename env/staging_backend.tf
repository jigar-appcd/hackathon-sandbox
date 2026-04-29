terraform {
  backend "s3" {
    region         = "us-east-1"
    bucket         = "<FILL_IN>"
    key            = "eks-base/staging.tfstate"
    encrypt        = "true"
    dynamodb_table = "<FILL_IN>"
  }
}
