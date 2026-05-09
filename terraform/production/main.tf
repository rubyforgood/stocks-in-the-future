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
  #   key    = "stocks-production/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_lightsail_instance" "production" {
  name              = "production_web"
  availability_zone = "${var.aws_region}a"
  blueprint_id      = "ubuntu_24_04"
  bundle_id         = var.instance_bundle_id
  key_pair_name     = var.lightsail_ssh_key_name

  tags = {
    Environment = "production"
    App         = "stocks-in-the-future"
    ManagedBy   = "terraform"
  }
}

resource "aws_lightsail_instance_public_ports" "production" {
  instance_name = aws_lightsail_instance.production.name

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

resource "aws_lightsail_database" "production" {
  relational_database_name = "production-db"
  availability_zone        = "${var.aws_region}a"
  master_database_name     = "stocks_in_the_future_production"
  master_username          = "dbmasteruser"
  master_password          = var.db_master_password
  blueprint_id             = "postgres_16"
  bundle_id                = var.db_bundle_id
  skip_final_snapshot      = false # always keep a snapshot when destroying production

  tags = {
    Environment = "production"
    App         = "stocks-in-the-future"
    ManagedBy   = "terraform"
  }
}

resource "aws_lightsail_lb" "production" {
  name              = "stocks-production-lb"
  instance_port     = 80
  health_check_path = "/up"

  tags = {
    Environment = "production"
    App         = "stocks-in-the-future"
    ManagedBy   = "terraform"
  }
}

resource "aws_lightsail_lb_attachment" "production" {
  lb_name       = aws_lightsail_lb.production.name
  instance_name = aws_lightsail_instance.production.name
}

resource "aws_lightsail_lb_certificate" "production" {
  name        = "production-ssl"
  lb_name     = aws_lightsail_lb.production.name
  domain_name = "app.sifonline.org"
}

resource "aws_lightsail_lb_certificate_attachment" "production" {
  lb_name          = aws_lightsail_lb.production.name
  certificate_name = aws_lightsail_lb_certificate.production.name
}
