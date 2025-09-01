# GKE Private Cluster Module

This module provisions a private Google Kubernetes Engine (GKE) cluster with security best practices.

## Purpose

Creates a production-ready private GKE cluster with:
- Private nodes (no public IP addresses)
- Workload Identity enabled for secure pod authentication
- Network policies for pod-to-pod communication control
- Configurable master authorized networks
- Auto-repair and auto-upgrade for nodes

## Usage Examples

### Basic Usage with New VPC

```hcl
module "gke" {
  source = "../../modules/gke"

  project_id              = "my-project-id"
  cluster_name            = "my-private-cluster"
  region                  = "us-central1"
  vpc_name                = "my-vpc"
  subnet_name             = "my-subnet"
  pods_range_name         = "pods-range"
  services_range_name     = "services-range"
  master_ipv4_cidr_block  = "10.1.0.0/28"
  node_count              = 3
  machine_type            = "e2-medium"
  service_account_email   = "my-sa@my-project.iam.gserviceaccount.com"
}
```

### Usage with Existing VPC

```hcl
module "gke" {
  source = "../../modules/gke"

  project_id              = "my-project-id"
  cluster_name            = "my-private-cluster"
  region                  = "us-central1"
  vpc_name                = "existing-vpc"
  subnet_name             = "existing-subnet"
  pods_range_name         = "k8s-pods"
  services_range_name     = "k8s-services"
  master_ipv4_cidr_block  = "172.16.0.0/28"
  enable_private_endpoint = true  # Fully private cluster
  
  master_authorized_networks = [
    {
      cidr_block   = "10.0.0.0/8"
      display_name = "internal"
    }
  ]
  
  node_count            = 5
  machine_type          = "n2-standard-4"
  preemptible          = true
  service_account_email = "gke-nodes@my-project.iam.gserviceaccount.com"
  
  node_labels = {
    environment = "production"
    team        = "platform"
  }
  
  node_tags = ["gke-node", "private", "production"]
}
```

## Module Composition Example

```hcl
# Create service account
resource "google_service_account" "gke_nodes" {
  account_id   = "${var.cluster_name}-nodes"
  display_name = "GKE Nodes Service Account"
  project      = var.project_id
}

# Grant required permissions
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

# Deploy GKE cluster
module "gke" {
  source = "./modules/gke"

  project_id            = var.project_id
  cluster_name          = var.cluster_name
  region                = var.region
  vpc_name              = google_compute_network.vpc.name
  subnet_name           = google_compute_subnetwork.subnet.name
  pods_range_name       = "pods-range"
  services_range_name   = "services-range"
  service_account_email = google_service_account.gke_nodes.email
  
  # ... other configurations
}
```

## Requirements

- Terraform >= 1.0
- Google Cloud Provider >= 4.50.0
- Required APIs enabled:
  - Kubernetes Engine API
  - Compute Engine API
  - IAM API

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_id | The GCP project ID | `string` | n/a | yes |
| cluster_name | The name of the GKE cluster | `string` | n/a | yes |
| region | The region for the GKE cluster | `string` | n/a | yes |
| vpc_name | The name of the VPC network | `string` | n/a | yes |
| subnet_name | The name of the subnet | `string` | n/a | yes |
| pods_range_name | The name of the secondary range for pods | `string` | n/a | yes |
| services_range_name | The name of the secondary range for services | `string` | n/a | yes |
| master_ipv4_cidr_block | The IP range in CIDR notation for the master | `string` | `"10.1.0.0/28"` | no |
| enable_private_endpoint | Whether the master's internal IP address is used as the cluster endpoint | `bool` | `false` | no |
| master_authorized_networks | List of master authorized networks | `list(object)` | `[]` | no |
| node_count | Number of nodes in the node pool | `number` | `3` | no |
| machine_type | Machine type for the nodes | `string` | `"e2-medium"` | no |
| preemptible | Whether to use preemptible nodes | `bool` | `false` | no |
| service_account_email | Service account email for the nodes | `string` | `""` | no |
| node_labels | Labels to apply to the nodes | `map(string)` | `{}` | no |
| node_tags | Network tags to apply to the nodes | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The ID of the GKE cluster |
| cluster_name | The name of the GKE cluster |
| cluster_endpoint | The endpoint for the GKE cluster (sensitive) |
| cluster_ca_certificate | The cluster CA certificate (sensitive) |
| region | The region of the GKE cluster |

## Network Architecture

The module creates a private GKE cluster with the following network configuration:

- **Private Nodes**: All nodes have only private IP addresses
- **Master CIDR**: Dedicated CIDR block for the Kubernetes master
- **Pod CIDR**: Secondary IP range for pod networking
- **Service CIDR**: Secondary IP range for Kubernetes services

## Security Features

- **Workload Identity**: Enabled for secure pod authentication to GCP services
- **Private Nodes**: No public IP addresses on nodes
- **Network Policies**: Enabled for fine-grained pod-to-pod communication control
- **Shielded Nodes**: Secure boot and integrity monitoring enabled
- **Auto-repair/Auto-upgrade**: Automatic node maintenance for security patches

## Notes

- The cluster is created with deletion protection enabled by default
- Workload Identity pool is automatically configured as `{project_id}.svc.id.goog`
- The default node pool is removed and replaced with a managed node pool
- All nodes have the metadata endpoint secured (disable-legacy-endpoints)