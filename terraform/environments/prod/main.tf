terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Remote state – update bucket name before first apply
  backend "gcs" {
    bucket = "REPLACE_WITH_YOUR_TF_STATE_BUCKET"
    prefix = "terraform/state/prod"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ── Networking ──────────────────────────────────────────────────────────────
module "networking" {
  source      = "../../modules/networking"
  project_id  = var.project_id
  region      = var.region
  app_name    = var.app_name
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
}

# ── IAM ─────────────────────────────────────────────────────────────────────
module "iam" {
  source      = "../../modules/iam"
  project_id  = var.project_id
  app_name    = var.app_name
  environment = var.environment
}

# ── Database ─────────────────────────────────────────────────────────────────
module "database" {
  source      = "../../modules/database"
  project_id  = var.project_id
  region      = var.region
  app_name    = var.app_name
  environment = var.environment
  vpc_name    = module.networking.vpc_name
  db_password = var.db_password
  db_tier     = var.db_tier
}

# ── Compute (Cloud Run) ──────────────────────────────────────────────────────
module "compute" {
  source                = "../../modules/compute"
  project_id            = var.project_id
  region                = var.region
  app_name              = var.app_name
  environment           = var.environment
  backend_image         = var.backend_image
  frontend_image        = var.frontend_image
  vpc_connector_id      = module.networking.vpc_connector_id
  service_account_email = module.iam.service_account_email
  db_host               = module.database.private_ip_address
  db_name               = module.database.database_name
  db_user               = module.database.db_user
  db_password           = var.db_password
}

# ── Monitoring ───────────────────────────────────────────────────────────────
module "monitoring" {
  source               = "../../modules/monitoring"
  project_id           = var.project_id
  app_name             = var.app_name
  environment          = var.environment
  alert_email          = var.alert_email
  backend_service_name = "${var.app_name}-${var.environment}-backend"
}
