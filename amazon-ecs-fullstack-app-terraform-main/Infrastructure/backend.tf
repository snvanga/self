terraform {
  backend "s3" {
    bucket = "ecs-fullstack-terraform-state-354482028472"
    key    = "ecs-fullstack/terraform.tfstate"
    region = "us-east-1"
  }
}