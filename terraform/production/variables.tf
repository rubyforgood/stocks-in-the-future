variable "aws_region" {
  default = "us-east-1"
}

variable "lightsail_ssh_key_name" {
  description = "Name of the existing Lightsail SSH key pair"
  type        = string
}

variable "instance_bundle_id" {
  description = "Lightsail instance bundle (size). Check AWS console for the existing production bundle ID."
  type        = string
  default     = "small_3_0"
}

variable "db_bundle_id" {
  description = "Lightsail managed database bundle ID. Check AWS console for the existing production DB bundle ID."
  type        = string
  default     = "micro_2_0"
}

variable "db_master_password" {
  description = "Master password for the production PostgreSQL database"
  type        = string
  sensitive   = true
}

variable "rails_master_key" {
  description = "Rails master key (contents of config/master.key)"
  type        = string
  sensitive   = true
}

variable "alpha_vantage_api_key" {
  description = "Alpha Vantage API key"
  type        = string
  sensitive   = true
}
