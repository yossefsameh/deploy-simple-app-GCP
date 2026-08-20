resource "google_cloud_run_v2_service" "backend" {
  project  = var.project_id
  name     = "${var.app_name}-${var.environment}-backend"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = var.service_account_email

    vpc_access {
      connector = var.vpc_connector_id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    containers {
      image = var.backend_image

      ports {
        container_port = 8080
      }

      env {
        name  = "PORT"
        value = "8080"
      }
      env {
        name  = "NODE_ENV"
        value = "production"
      }
      env {
        name  = "DB_HOST"
        value = var.db_host
      }
      env {
        name  = "DB_NAME"
        value = var.db_name
      }
      env {
        name  = "DB_USER"
        value = var.db_user
      }
      dynamic "env" {
        for_each = var.db_password_secret != "" ? [1] : []
        content {
          name = "DB_PASSWORD"
          value_source {
            secret_key_ref {
              secret  = var.db_password_secret
              version = "latest"
            }
          }
        }
      }
      env {
        name  = "DB_SSL"
        value = "true"
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        cpu_idle = true
      }

      liveness_probe {
        http_get {
          path = "/health"
          port = 8080
        }
        initial_delay_seconds = 10
        period_seconds        = 30
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 3
    }

    labels = {
      app         = var.app_name
      environment = var.environment
      tier        = "backend"
      managed-by  = "terraform"
    }
  }
}

# Allow unauthenticated access to the backend (public API)
resource "google_cloud_run_v2_service_iam_member" "backend_public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.backend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_v2_service" "frontend" {
  project  = var.project_id
  name     = "${var.app_name}-${var.environment}-frontend"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = var.service_account_email

    containers {
      image = var.frontend_image

      ports {
        container_port = 80
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "256Mi"
        }
        cpu_idle = true
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 3
    }

    labels = {
      app         = var.app_name
      environment = var.environment
      tier        = "frontend"
      managed-by  = "terraform"
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "frontend_public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.frontend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
