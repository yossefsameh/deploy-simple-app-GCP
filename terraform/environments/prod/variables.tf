variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "three-tier-app"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR range for the app subnet"
  type        = string
  default     = "10.10.0.0/24"
}

variable "db_tier" {
  description = "Cloud SQL machine tier"
  type        = string
  default     = "db-f1-micro"
}

variable "db_password" {
  description = "DB password – supply via TF_VAR_db_password or Terraform Cloud variable"
  type        = string
  sensitive   = true
}

variable "backend_image" {
  description = "Full Docker image URI for the backend (e.g. gcr.io/PROJECT/backend:TAG)"
  type        = string
}

variable "frontend_image" {
  description = "Full Docker image URI for the frontend (e.g. gcr.io/PROJECT/frontend:TAG)"
  type        = string
}

variable "alert_email" {
  description = "Email address for monitoring alerts"
  type        = string
}
