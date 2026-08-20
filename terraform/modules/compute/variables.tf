variable "project_id"        { type = string }
variable "region"            { type = string }
variable "app_name"          { type = string }
variable "environment"       { type = string }
variable "backend_image"     { type = string; description = "Full Docker image URI for the backend" }
variable "frontend_image"    { type = string; description = "Full Docker image URI for the frontend" }
variable "vpc_connector_id"  { type = string }
variable "service_account_email" { type = string }

variable "db_host"            { type = string; default = "" }
variable "db_name"            { type = string; default = "appdb" }
variable "db_user"            { type = string; default = "appuser" }
variable "db_password_secret" {
  description = "Secret Manager secret ID that holds the DB password"
  type        = string
  default     = ""
}
