# Terraform GKE Private Deployment

Welcome to the documentation for the Terraform GKE Private Deployment project.

## Overview

This project provides a production-ready, modular Terraform solution for deploying a private Google Kubernetes Engine (GKE) cluster with a hello-nginx application. The solution emphasizes security, privacy, and reusability, making it ideal for healthcare and other security-conscious environments.

## Quick Links

- [Implementation Plan](implementation-plan.md) - High-level approach and design decisions
- [Architecture Documentation](architecture.md) - System and component architecture
- [GKE Module](modules/gke.md) - Private cluster provisioning module
- [Helm App Module](modules/helm-app.md) - Application deployment module
- [Development Example](examples/dev.md) - Complete working example

## Key Features

### 🔒 Security First
- Private nodes with no public IP addresses
- Workload Identity for secure pod authentication
- Network policies for granular traffic control
- Minimal IAM permissions following least privilege

### 🔧 Modular Design
- Reusable Terraform modules
- Environment-agnostic configuration
- Clear separation of infrastructure and application concerns
- Composable architecture for different use cases

### 📊 Production Ready
- Comprehensive documentation
- Idempotent and safe to apply multiple times
- Support for existing VPC or new VPC creation
- Auto-repair and auto-upgrade for nodes

## Getting Started

### Prerequisites

1. **Google Cloud Project** with billing enabled
2. **Service Account** with appropriate permissions
3. **Terraform** >= 1.0
4. **Google Cloud SDK** (gcloud)

### Quick Start

```bash
# Clone the repository
git clone https://github.com/badara10/terraform-gke-private-deployment.git
cd terraform-gke-private-deployment

# Navigate to the example
cd examples/dev

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy the infrastructure
terraform apply

# Configure kubectl
gcloud container clusters get-credentials private-gke-cluster \
  --region us-central1 \
  --project your-project-id

# Verify deployment
kubectl get pods -n hello-app
```

## Project Structure

```
.
├── modules/
│   ├── gke/            # Private GKE cluster module
│   └── helm_app/       # Helm application deployment
├── examples/
│   └── dev/            # Development environment example
├── docs/               # Documentation
├── flake.nix          # Nix development environment
└── README.md          # Project overview
```

## Network Architecture

The solution uses the **10.1.2.0/18** IP block with careful allocation:

| Range | CIDR | Purpose | IP Count |
|-------|------|---------|----------|
| Master | 10.1.0.0/28 | Control plane | 16 |
| Nodes | 10.1.2.0/24 | Worker nodes | 256 |
| Pods | 10.1.4.0/22 | Pod networking | 1,024 |
| Services | 10.1.8.0/22 | Kubernetes services | 1,024 |

## Module Overview

### GKE Module
Creates a private GKE cluster with:
- Private nodes (no public IPs)
- Configurable VPC (new or existing)
- Workload Identity enabled
- Network policies
- Auto-repair and auto-upgrade

### Helm App Module
Deploys applications via Helm:
- Namespace management
- Configurable resources
- Service exposure
- Custom values support

## Security Considerations

!!! warning "Production Security"
    For production deployments, ensure you:
    
    - Restrict master authorized networks
    - Use private endpoints only
    - Implement proper secret management
    - Enable audit logging
    - Configure network policies

## Development Environment

### Using Nix

This project includes a Nix development environment with all required tools:

```bash
# With flakes enabled
nix develop

# Or using traditional nix-shell
nix-shell
```

### Starting Documentation Server

```bash
# Using mkdocs directly
cd docs && mkdocs serve

# Or using the Makefile
make docs-serve
```

## Support

For issues or questions:
- Review the [documentation](https://github.com/badara10/terraform-gke-private-deployment/tree/main/docs)
- Check [module examples](https://github.com/badara10/terraform-gke-private-deployment/tree/main/examples)
- Open an [issue on GitHub](https://github.com/badara10/terraform-gke-private-deployment/issues)

## License

This project is provided as-is for educational and development purposes.