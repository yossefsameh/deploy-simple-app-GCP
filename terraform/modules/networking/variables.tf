variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Deployment environment (e.g. prod, staging)"
  type        = string
  default     = "prod"
}

variable "app_name" {
  description = "Application name used in resource naming"
  type        = string
  default     = "three-tier-app"
}

variable "vpc_cidr" {
  description = "CIDR for the primary subnet"
  type        = string
  default     = "10.10.0.0/24"
}
