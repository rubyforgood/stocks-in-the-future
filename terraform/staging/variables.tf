variable "aws_region" {
  default = "us-east-1"
}

variable "lightsail_ssh_key_name" {
  description = "Name of the existing Lightsail SSH key pair"
  type        = string
}

variable "db_master_password" {
  description = "Master password for the staging PostgreSQL database"
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
