variable "project_id"           { type = string }
variable "app_name"             { type = string }
variable "environment"          { type = string }
variable "alert_email"          { type = string; description = "Email address for alert notifications" }
variable "backend_service_name" { type = string }
