# Terraform GKE Private Deployment

A modular Terraform project for provisioning a private Google Kubernetes Engine (GKE) cluster with a hello-nginx application deployment.

## Project Overview

This project provides reusable Terraform modules for deploying:
- A secure, private GKE cluster with best practices
- A hello-nginx application via Helm
- Complete example configurations for different environments

## Project Structure

```
.
├── modules/
│   ├── gke/            # Private GKE cluster module
│   └── helm_app/       # Helm application deployment module
├── examples/
│   └── dev/            # Development environment example
├── docs/               # Additional documentation
└── README.md           # This file
```

## Quick Start

### Prerequisites

- Terraform >= 1.0
- Google Cloud SDK (gcloud)
- Active GCP project with billing enabled
- Service account with appropriate permissions

### Deploy Development Environment

1. **Navigate to the example**:
   ```bash
   cd examples/dev
   ```

2. **Configure your credentials**:
   ```bash
   # Update the credentials path in terraform.tfvars
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your settings
   ```

3. **Deploy the infrastructure**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Access the cluster**:
   ```bash
   gcloud container clusters get-credentials private-gke-cluster \
     --region us-central1 \
     --project your-project-id
   
   kubectl get pods -n hello-app
   ```

## Modules

### GKE Module

Creates a private GKE cluster with security features:

```hcl
module "gke" {
  source = "./modules/gke"

  project_id          = "my-project"
  cluster_name        = "my-cluster"
  region              = "us-central1"
  vpc_name            = "my-vpc"
  subnet_name         = "my-subnet"
  pods_range_name     = "pods"
  services_range_name = "services"
}
```

Key features:
- Private nodes (no public IPs)
- Workload Identity enabled
- Network policies
- Auto-repair and auto-upgrade

[Full documentation](modules/gke/README.md)

### Helm App Module

Deploys applications using Helm:

```hcl
module "app" {
  source = "./modules/helm_app"

  release_name     = "my-app"
  namespace        = "apps"
  create_namespace = true
  replica_count    = 3
}
```

Features:
- Namespace management
- Resource configuration
- Custom values support

[Full documentation](modules/helm_app/README.md)

## Network Architecture

The project uses a well-structured IP allocation strategy:

| Component | CIDR Block | Purpose |
|-----------|------------|---------|
| VPC Subnet | 10.1.2.0/24 | Node IP addresses |
| Pods Range | 10.1.4.0/22 | Pod networking (1024 IPs) |
| Services Range | 10.1.8.0/22 | Kubernetes services (1024 IPs) |
| Master Range | 10.1.0.0/28 | Control plane IPs |

## Security Features

- **Private Cluster**: All nodes have private IPs only
- **Workload Identity**: Secure pod authentication to GCP services
- **Network Policies**: Control pod-to-pod communication
- **Minimal IAM**: Service accounts with least privilege
- **Shielded Nodes**: Secure boot and integrity monitoring

## Examples

### Development Environment

Complete example with:
- New VPC creation
- 3-node private cluster
- hello-nginx deployment
- LoadBalancer service

[View example](examples/dev/)

### Production Configuration

For production, consider:
- Restricting master authorized networks
- Using preemptible nodes for cost savings
- Implementing proper backup strategies
- Setting up monitoring and alerting

## Required APIs

The following Google Cloud APIs must be enabled:
- Compute Engine API
- Kubernetes Engine API
- Identity and Access Management API
- Cloud Resource Manager API

Enable them with:
```bash
gcloud services enable \
  compute.googleapis.com \
  container.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com
```

## IAM Requirements

The service account needs these roles:
- `roles/container.admin` - Manage GKE clusters
- `roles/compute.admin` - Manage compute resources
- `roles/iam.serviceAccountAdmin` - Manage service accounts
- `roles/resourcemanager.projectIamAdmin` - Manage project IAM

## Customization

### Using Existing VPC

```hcl
module "gke" {
  source = "./modules/gke"
  
  # Use existing network
  vpc_name    = "existing-vpc"
  subnet_name = "existing-subnet"
  # ... other configuration
}
```

### Multi-Environment Setup

Structure your environments:
```
examples/
├── dev/
├── staging/
└── production/
```

Each with environment-specific configurations.

## Best Practices

1. **State Management**: Use remote state backend (GCS, Terraform Cloud)
2. **Secrets**: Never commit credentials; use Secret Manager
3. **Networking**: Keep clusters private; use Cloud NAT for egress
4. **Monitoring**: Enable GKE monitoring and logging
5. **Updates**: Regular updates for security patches

## Troubleshooting

### Common Issues

**API Not Enabled**:
```bash
gcloud services list --enabled
# Enable missing APIs as shown above
```

**Insufficient Quota**:
```bash
gcloud compute project-info describe
# Request quota increase if needed
```

**Authentication Issues**:
```bash
gcloud auth application-default login
# Or use service account key
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/key.json"
```

## Cost Optimization

- Use preemptible nodes for non-critical workloads
- Right-size your nodes based on actual usage
- Implement cluster autoscaling
- Use committed use discounts for production

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is provided as-is for educational and development purposes.

## Support

For issues and questions:
- Check the [module documentation](modules/)
- Review the [examples](examples/)
- Consult the [Terraform GCP documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

## Roadmap

- [ ] Add monitoring and observability modules
- [ ] Implement GitOps with Flux/ArgoCD
- [ ] Add backup and disaster recovery
- [ ] Create staging and production examples
- [ ] Add cost estimation tools