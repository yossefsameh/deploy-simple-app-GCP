resource "google_compute_network" "vpc" {
  project                 = var.project_id
  name                    = "${var.app_name}-${var.environment}-vpc"
  auto_create_subnetworks = false

  description = "VPC for ${var.app_name} (${var.environment})"
}

resource "google_compute_subnetwork" "app_subnet" {
  project       = var.project_id
  name          = "${var.app_name}-${var.environment}-subnet"
  network       = google_compute_network.vpc.id
  region        = var.region
  ip_cidr_range = var.vpc_cidr

  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# VPC connector so Cloud Run can reach Cloud SQL via private IP
resource "google_vpc_access_connector" "connector" {
  project       = var.project_id
  name          = "${var.app_name}-${var.environment}-vpc-cx"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.8.0.0/28"
  min_throughput = 200
  max_throughput = 300
}

# Firewall – deny all ingress by default; allow only health-check probes from GCP
resource "google_compute_firewall" "allow_health_checks" {
  project = var.project_id
  name    = "${var.app_name}-${var.environment}-allow-hc"
  network = google_compute_network.vpc.name

  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
    ports    = ["8080", "80"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["${var.app_name}-${var.environment}"]
  description   = "Allow GCP health-check probes"
}
