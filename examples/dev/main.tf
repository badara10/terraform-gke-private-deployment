provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project_id
  region      = var.region
}

# Create VPC if not using existing
resource "google_compute_network" "vpc" {
  count                   = var.create_vpc ? 1 : 0
  name                    = var.vpc_name
  auto_create_subnetworks = false
  project                 = var.project_id

  depends_on = [
    google_project_service.compute
  ]
}

# Create subnet with secondary ranges for pods and services
resource "google_compute_subnetwork" "subnet" {
  count         = var.create_vpc ? 1 : 0
  name          = var.subnet_name
  ip_cidr_range = "10.1.2.0/24" # Node range from the 10.1.2.0/18 block
  region        = var.region
  network       = google_compute_network.vpc[0].id
  project       = var.project_id

  secondary_ip_range {
    range_name    = "pods-range"
    ip_cidr_range = "10.1.4.0/22" # Pod range from the 10.1.2.0/18 block (1024 IPs)
  }

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "10.1.8.0/22" # Service range from the 10.1.2.0/18 block (1024 IPs)
  }

  private_ip_google_access = true
}

# Create service account for GKE nodes
resource "google_service_account" "gke_nodes" {
  account_id   = "${var.cluster_name}-nodes"
  display_name = "GKE Nodes Service Account"
  project      = var.project_id

  depends_on = [
    google_project_service.iam
  ]
}

# Grant necessary permissions to the service account
resource "google_project_iam_member" "gke_nodes_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# GKE Cluster
module "gke" {
  source = "../../modules/gke"

  project_id              = var.project_id
  cluster_name            = var.cluster_name
  region                  = var.region
  vpc_name                = var.create_vpc ? google_compute_network.vpc[0].name : var.vpc_name
  subnet_name             = var.create_vpc ? google_compute_subnetwork.subnet[0].name : var.subnet_name
  pods_range_name         = "pods-range"
  services_range_name     = "services-range"
  master_ipv4_cidr_block  = "10.1.0.0/28"
  enable_private_endpoint = false # Set to false for initial access
  master_authorized_networks = [
    {
      cidr_block   = "0.0.0.0/0" # WARNING: This allows access from anywhere. Restrict in production!
      display_name = "all"
    }
  ]
  node_count            = var.node_count
  machine_type          = var.machine_type
  preemptible           = var.preemptible
  disk_size_gb          = var.disk_size_gb
  disk_type             = var.disk_type
  service_account_email = google_service_account.gke_nodes.email
  node_labels = {
    environment = "dev"
    managed_by  = "terraform"
  }
  node_tags = ["gke-node", "private"]

  depends_on = [
    google_project_service.container,
    google_project_service.compute
  ]
}

# Configure Kubernetes and Helm providers
data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.cluster_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
}

provider "helm" {
  kubernetes = {
    host                   = "https://${module.gke.cluster_endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
  }
}

# Deploy hello-nginx application
module "hello_nginx" {
  source = "../../modules/helm_app"

  release_name     = "hello-nginx"
  namespace        = "hello-app"
  create_namespace = true
  replica_count    = 2

  depends_on = [module.gke]
}