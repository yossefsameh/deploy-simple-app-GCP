output "instance_name" {
  value = google_sql_database_instance.postgres.name
}

output "private_ip_address" {
  description = "Private IP of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.private_ip_address
}

output "connection_name" {
  description = "Cloud SQL connection name for the proxy"
  value       = google_sql_database_instance.postgres.connection_name
}

output "database_name" {
  value = google_sql_database.appdb.name
}

output "db_user" {
  value = google_sql_user.appuser.name
}
