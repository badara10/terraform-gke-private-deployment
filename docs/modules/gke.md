# GKE Module Documentation

## Overview

The GKE module provisions a private Google Kubernetes Engine cluster with enterprise-grade security features. This module is designed for production use in security-conscious environments, particularly healthcare.

## Features

- ✅ Private nodes with no public IPs
- ✅ Workload Identity for secure authentication
- ✅ Network policies enabled
- ✅ Flexible VPC configuration
- ✅ Auto-repair and auto-upgrade
- ✅ Shielded nodes with secure boot

## Module Source

```hcl
module "gke" {
  source = "./modules/gke"
  # or from GitHub
  source = "github.com/badara10/terraform-gke-private-deployment//modules/gke"
}
```

## Input Variables

| Variable | Type | Description | Default | Required |
|----------|------|-------------|---------|----------|
| `project_id` | string | GCP project ID | - | yes |
| `cluster_name` | string | Name of the GKE cluster | - | yes |
| `region` | string | GCP region for the cluster | - | yes |
| `vpc_name` | string | Name of the VPC network | - | yes |
| `subnet_name` | string | Name of the subnet | - | yes |
| `pods_range_name` | string | Secondary range name for pods | - | yes |
| `services_range_name` | string | Secondary range name for services | - | yes |
| `master_ipv4_cidr_block` | string | CIDR block for master | `10.1.0.0/28` | no |
| `enable_private_endpoint` | bool | Use private endpoint only | `false` | no |
| `master_authorized_networks` | list | Authorized networks | `[]` | no |
| `node_count` | number | Number of nodes | `3` | no |
| `machine_type` | string | Node machine type | `e2-medium` | no |
| `preemptible` | bool | Use preemptible nodes | `false` | no |
| `service_account_email` | string | Service account for nodes | `""` | no |
| `node_labels` | map | Labels for nodes | `{}` | no |
| `node_tags` | list | Network tags for nodes | `[]` | no |

## Output Values

| Output | Type | Description | Sensitive |
|--------|------|-------------|-----------|
| `cluster_id` | string | Cluster ID | no |
| `cluster_name` | string | Cluster name | no |
| `cluster_endpoint` | string | API endpoint | yes |
| `cluster_ca_certificate` | string | CA certificate | yes |
| `region` | string | Cluster region | no |

## Usage Examples

### Basic Private Cluster

```hcl
module "gke" {
  source = "./modules/gke"

  project_id          = "my-project-id"
  cluster_name        = "my-private-cluster"
  region              = "us-central1"
  vpc_name            = "my-vpc"
  subnet_name         = "my-subnet"
  pods_range_name     = "pods-range"
  services_range_name = "services-range"
  
  service_account_email = google_service_account.gke_nodes.email
}
```

### Production Configuration

```hcl
module "gke" {
  source = "./modules/gke"

  project_id              = var.project_id
  cluster_name            = "${var.environment}-gke-cluster"
  region                  = var.region
  vpc_name                = google_compute_network.vpc.name
  subnet_name             = google_compute_subnetwork.subnet.name
  pods_range_name         = "pods-range"
  services_range_name     = "services-range"
  master_ipv4_cidr_block  = "172.16.0.0/28"
  enable_private_endpoint = true
  
  master_authorized_networks = [
    {
      cidr_block   = "10.0.0.0/8"
      display_name = "internal"
    },
    {
      cidr_block   = var.office_ip
      display_name = "office"
    }
  ]
  
  node_count            = 5
  machine_type          = "n2-standard-4"
  preemptible          = false
  service_account_email = google_service_account.gke_nodes.email
  
  node_labels = {
    environment = var.environment
    team        = "platform"
    managed_by  = "terraform"
  }
  
  node_tags = ["gke-node", "private", var.environment]
}
```

### With Existing VPC

```hcl
data "google_compute_network" "existing" {
  name = "existing-vpc"
}

data "google_compute_subnetwork" "existing" {
  name   = "existing-subnet"
  region = "us-central1"
}

module "gke" {
  source = "./modules/gke"

  project_id          = var.project_id
  cluster_name        = "my-cluster"
  region              = "us-central1"
  vpc_name            = data.google_compute_network.existing.name
  subnet_name         = data.google_compute_subnetwork.existing.name
  pods_range_name     = "k8s-pods"
  services_range_name = "k8s-services"
  
  # ... other configuration
}
```

## Network Requirements

### Required Secondary Ranges

The subnet must have two secondary IP ranges configured:

```hcl
resource "google_compute_subnetwork" "subnet" {
  name          = "gke-subnet"
  ip_cidr_range = "10.1.2.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc.id

  secondary_ip_range {
    range_name    = "pods-range"
    ip_cidr_range = "10.1.4.0/22"
  }

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "10.1.8.0/22"
  }

  private_ip_google_access = true
}
```

## IAM Requirements

The service account needs these minimum roles:

```hcl
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
```

## Security Best Practices

!!! warning "Production Security"
    Always implement these security measures for production:

1. **Enable Private Endpoint**
   ```hcl
   enable_private_endpoint = true
   ```

2. **Restrict Master Access**
   ```hcl
   master_authorized_networks = [
     {
       cidr_block   = "10.0.0.0/8"
       display_name = "internal-only"
     }
   ]
   ```

3. **Use Dedicated Service Account**
   ```hcl
   service_account_email = google_service_account.gke_nodes.email
   ```

4. **Enable Network Policies**
   - Already enabled by default in the module

5. **Use Workload Identity**
   - Already configured in the module

## Troubleshooting

### Common Issues

**Cluster Creation Timeout**
- Check if APIs are enabled
- Verify quota availability
- Review service account permissions

**Network Configuration Errors**
- Ensure secondary ranges don't overlap
- Verify VPC and subnet exist
- Check firewall rules

**Access Issues**
- Verify master authorized networks
- Check kubectl configuration
- Ensure proper IAM permissions

## Related Documentation

- [Helm App Module](helm-app.md)
- [Architecture Overview](../architecture.md)
- [Development Example](../examples/dev.md)