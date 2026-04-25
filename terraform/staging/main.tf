terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Recommended: store state in S3 to share with teammates
  # backend "s3" {
  #   bucket = "your-tf-state-bucket"
  #   key    = "stocks-staging/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_lightsail_instance" "staging" {
  name              = "staging_web"
  availability_zone = "${var.aws_region}a"
  blueprint_id      = "ubuntu_24_04"
  bundle_id         = "small_3_0" # 2 GB RAM, 1 vCPU
  key_pair_name     = var.lightsail_ssh_key_name

  user_data = templatefile("${path.module}/bootstrap.sh", {
    rails_master_key      = var.rails_master_key
    db_password           = var.db_master_password
    alpha_vantage_api_key = var.alpha_vantage_api_key
    rails_env             = "staging"
    app_name              = "stocks-in-the-future"
  })

  tags = {
    Environment = "staging"
    App         = "stocks-in-the-future"
    ManagedBy   = "terraform"
  }
}

resource "aws_lightsail_instance_public_ports" "staging" {
  instance_name = aws_lightsail_instance.staging.name

  port_info {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }

  port_info {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
  }
}

resource "aws_lightsail_database" "staging" {
  relational_database_name = "stocks-staging-db"
  availability_zone        = "${var.aws_region}a"
  master_database_name     = "stocks_staging"
  master_username          = "stocks_user"
  master_password          = var.db_master_password
  blueprint_id             = "postgres_16"
  bundle_id                = "micro_2_0"
  skip_final_snapshot      = true

  tags = {
    Environment = "staging"
    App         = "stocks-in-the-future"
    ManagedBy   = "terraform"
  }
}

resource "aws_lightsail_lb" "staging" {
  name              = "staging-lb"
  instance_port     = 80
  health_check_path = "/up"

  tags = {
    Environment = "staging"
    App         = "stocks-in-the-future"
    ManagedBy   = "terraform"
  }
}

resource "aws_lightsail_lb_attachment" "staging" {
  lb_name       = aws_lightsail_lb.staging.name
  instance_name = aws_lightsail_instance.staging.name
}
