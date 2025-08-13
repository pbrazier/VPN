terraform {
  backend "s3" {
    # Configuration will be provided by init command
    # bucket         = "<bucket-name>"
    # key            = "tailscale-exit-nodes/terraform.tfstate"
    # region         = "eu-west-2"
    # encrypt        = true
    # dynamodb_table = "terraform-state-lock"
  }
}