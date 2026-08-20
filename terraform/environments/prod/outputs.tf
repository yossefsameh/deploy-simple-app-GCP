output "backend_url" {
  description = "Public URL of the backend Cloud Run service"
  value       = module.compute.backend_url
}

output "frontend_url" {
  description = "Public URL of the frontend Cloud Run service"
  value       = module.compute.frontend_url
}

output "db_connection_name" {
  description = "Cloud SQL connection name"
  value       = module.database.connection_name
}
