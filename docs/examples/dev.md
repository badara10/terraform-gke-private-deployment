# Development Environment Example

## Overview

This example demonstrates a complete deployment of a private GKE cluster with hello-nginx application in a development environment.

## Features

- ✅ Complete working example
- ✅ API enablement included
- ✅ New VPC creation
- ✅ Service account setup
- ✅ Both modules integrated

## Quick Start

### 1. Prerequisites

- GCP Project with billing enabled
- Service account key file
- Terraform >= 1.0
- gcloud CLI installed

### 2. Configuration

Create `terraform.tfvars`:

```hcl
credentials_file = "/path/to/credentials.json"
project_id       = "your-project-id"
region           = "us-central1"
cluster_name     = "private-gke-cluster"
node_count       = 3
machine_type     = "e2-medium"
```

### 3. Deployment

```bash
# Navigate to example
cd examples/dev

# Initialize Terraform
terraform init

# Review plan
terraform plan

# Deploy infrastructure
terraform apply

# Configure kubectl
gcloud container clusters get-credentials private-gke-cluster \
  --region us-central1 \
  --project your-project-id
```

## File Structure

```
examples/dev/
├── main.tf               # Main configuration
├── variables.tf          # Input variables
├── outputs.tf           # Output values
├── versions.tf          # Provider versions
├── apis.tf              # API enablement
├── terraform.tfvars.example  # Example variables
└── README.md            # This documentation
```

## Configuration Details

### Network Configuration

```hcl
# VPC with custom subnet
resource "google_compute_network" "vpc" {
  name                    = "gke-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "gke-subnet"
  ip_cidr_range = "10.1.2.0/24"  # Nodes
  
  secondary_ip_range {
    range_name    = "pods-range"
    ip_cidr_range = "10.1.4.0/22"  # Pods (1024 IPs)
  }
  
  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "10.1.8.0/22"  # Services (1024 IPs)
  }
}
```

### Service Account Setup

```hcl
resource "google_service_account" "gke_nodes" {
  account_id   = "${var.cluster_name}-nodes"
  display_name = "GKE Nodes Service Account"
}

# Required IAM roles
resource "google_project_iam_member" "gke_nodes_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}
```

### Module Integration

```hcl
# GKE Cluster
module "gke" {
  source = "../../modules/gke"
  
  project_id              = var.project_id
  cluster_name            = var.cluster_name
  region                  = var.region
  vpc_name                = google_compute_network.vpc.name
  subnet_name             = google_compute_subnetwork.subnet.name
  pods_range_name         = "pods-range"
  services_range_name     = "services-range"
  service_account_email   = google_service_account.gke_nodes.email
  
  depends_on = [
    google_project_service.container,
    google_project_service.compute
  ]
}

# Application Deployment
module "hello_nginx" {
  source = "../../modules/helm_app"
  
  release_name     = "hello-nginx"
  namespace        = "hello-app"
  create_namespace = true
  replica_count    = 2
  
  depends_on = [module.gke]
}
```

## Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `credentials_file` | Path to GCP credentials | `/home/user/creds.json` |
| `project_id` | GCP project ID | `my-project-123` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `region` | GCP region | `us-central1` |
| `cluster_name` | Cluster name | `private-gke-cluster` |
| `node_count` | Number of nodes | `3` |
| `machine_type` | Node machine type | `e2-medium` |
| `preemptible` | Use preemptible nodes | `false` |
| `create_vpc` | Create new VPC | `true` |

## Outputs

After successful deployment:

```bash
# View outputs
terraform output

# Outputs:
cluster_name = "private-gke-cluster"
cluster_region = "us-central1"
hello_nginx_namespace = "hello-app"
hello_nginx_release_name = "hello-nginx"
kubectl_config_command = "gcloud container clusters..."
```

## Verification

### Check Cluster

```bash
# Get cluster info
gcloud container clusters describe private-gke-cluster \
  --region us-central1

# Check nodes
kubectl get nodes

# Verify private IPs
kubectl get nodes -o wide
```

### Check Application

```bash
# Get pods
kubectl get pods -n hello-app

# Get service
kubectl get svc -n hello-app

# Get external IP
kubectl get svc -n hello-app hello-nginx \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Test application
curl http://<EXTERNAL_IP>
```

## Customization

### Using Existing VPC

```hcl
# terraform.tfvars
create_vpc  = false
vpc_name    = "existing-vpc"
subnet_name = "existing-subnet"
```

### Production Settings

```hcl
# terraform.tfvars
node_count   = 5
machine_type = "n2-standard-4"
preemptible  = false

# main.tf - Add master restrictions
master_authorized_networks = [
  {
    cidr_block   = "203.0.113.0/24"
    display_name = "office"
  }
]
```

### Cost Optimization

```hcl
# Use preemptible nodes
preemptible = true

# Smaller machine types
machine_type = "e2-micro"

# Reduce node count
node_count = 1
```

## Troubleshooting

### API Not Enabled

```bash
# Enable required APIs
gcloud services enable \
  compute.googleapis.com \
  container.googleapis.com \
  iam.googleapis.com \
  --project=your-project-id
```

### Permission Issues

```bash
# Check service account roles
gcloud projects get-iam-policy your-project-id \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:*"
```

### Network Issues

```bash
# Check firewall rules
gcloud compute firewall-rules list

# Check routes
gcloud compute routes list
```

### Cluster Access

```bash
# Update kubeconfig
gcloud container clusters get-credentials private-gke-cluster \
  --region us-central1 \
  --project your-project-id

# Test connection
kubectl cluster-info
```

## Cleanup

To destroy all resources:

```bash
# Destroy infrastructure
terraform destroy

# Confirm with 'yes'
```

!!! warning "Deletion Protection"
    The cluster has deletion protection enabled by default. You may need to:
    
    1. Manually disable deletion protection
    2. Or delete via console if Terraform fails

## Cost Estimation

Approximate monthly costs (us-central1):

| Resource | Specification | Cost/Month |
|----------|--------------|------------|
| GKE Management | 1 cluster | $0 (first free) |
| Compute (nodes) | 3x e2-medium | ~$75 |
| Load Balancer | 1 forwarding rule | ~$20 |
| Network | Egress traffic | Variable |
| **Total** | **Minimum** | **~$95** |

## Next Steps

1. **Security Hardening**
   - Restrict master authorized networks
   - Enable private endpoint
   - Implement network policies

2. **Monitoring Setup**
   - Enable GKE monitoring
   - Configure alerts
   - Set up dashboards

3. **CI/CD Integration**
   - Set up GitOps
   - Configure automated deployments
   - Implement testing pipeline

## Related Documentation

- [GKE Module](../modules/gke.md)
- [Helm App Module](../modules/helm-app.md)
- [Architecture Overview](../architecture.md)
- [Implementation Plan](../implementation-plan.md)