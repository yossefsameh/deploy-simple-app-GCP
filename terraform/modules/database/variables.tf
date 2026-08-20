variable "project_id" { type = string }
variable "region"     { type = string }
variable "app_name"   { type = string }
variable "environment" { type = string }
variable "vpc_name"   { type = string }
variable "db_password" {
  description = "Password for the application DB user"
  type        = string
  sensitive   = true
}
variable "db_tier" {
  description = "Cloud SQL machine tier"
  type        = string
  default     = "db-f1-micro"
}
