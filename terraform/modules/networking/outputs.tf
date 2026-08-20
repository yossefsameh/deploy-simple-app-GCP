output "vpc_id" {
  description = "Self-link of the VPC network"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "subnet_id" {
  description = "Self-link of the app subnet"
  value       = google_compute_subnetwork.app_subnet.id
}

output "vpc_connector_id" {
  description = "ID of the Serverless VPC Access connector"
  value       = google_vpc_access_connector.connector.id
}
