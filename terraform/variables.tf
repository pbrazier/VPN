# Region selection with friendly names
variable "region" {
  description = "Friendly region name for deployment"
  type        = string
  default     = "virginia"
  
  validation {
    condition = contains([
      "virginia", "ohio", "oregon", "ireland", 
      "london", "paris", "frankfurt", "singapore", 
      "sydney", "tokyo", "mumbai", "canada"
    ], var.region)
    error_message = "Region must be one of: virginia, ohio, oregon, ireland, london, paris, frankfurt, singapore, sydney, tokyo, mumbai, canada."
  }
}

# Map friendly names to AWS regions
locals {
  region_map = {
    virginia   = "us-east-1"
    ohio       = "us-east-2"
    oregon     = "us-west-2"
    ireland    = "eu-west-1"
    london     = "eu-west-2"
    paris      = "eu-west-3"
    frankfurt  = "eu-central-1"
    singapore  = "ap-southeast-1"
    sydney     = "ap-southeast-2"
    tokyo      = "ap-northeast-1"
    mumbai     = "ap-south-1"
    canada     = "ca-central-1"
  }
  
  aws_region    = local.region_map[var.region]
  instance_name = "ts-${var.region}"
}



