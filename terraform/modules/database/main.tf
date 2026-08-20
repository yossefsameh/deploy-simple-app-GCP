resource "google_sql_database_instance" "postgres" {
  project          = var.project_id
  name             = "${var.app_name}-${var.environment}-db"
  region           = var.region
  database_version = "POSTGRES_15"

  deletion_protection = true

  settings {
    tier              = var.db_tier
    availability_type = "ZONAL"
    disk_autoresize   = true
    disk_type         = "PD_SSD"

    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_disconnections"
      value = "on"
    }

    # Private IP only – no public IP
    ip_configuration {
      ipv4_enabled    = false
      private_network = "projects/${var.project_id}/global/networks/${var.vpc_name}"

      require_ssl = true
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }

    insights_config {
      query_insights_enabled = true
    }
  }

  labels = {
    app         = var.app_name
    environment = var.environment
    managed-by  = "terraform"
  }
}

resource "google_sql_database" "appdb" {
  project  = var.project_id
  instance = google_sql_database_instance.postgres.name
  name     = "appdb"
}

resource "google_sql_user" "appuser" {
  project  = var.project_id
  instance = google_sql_database_instance.postgres.name
  name     = "appuser"
  password = var.db_password
}
