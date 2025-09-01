# Helm App Module Documentation

## Overview

The Helm App module deploys applications to Kubernetes using Helm charts. It's designed to deploy a hello-nginx application but can be adapted for any Helm chart deployment.

## Features

- ✅ Namespace management
- ✅ Configurable resource limits
- ✅ Custom Helm values support
- ✅ Service exposure configuration
- ✅ Idempotent deployments

## Module Source

```hcl
module "helm_app" {
  source = "./modules/helm_app"
  # or from GitHub
  source = "github.com/badara10/terraform-gke-private-deployment//modules/helm_app"
}
```

## Input Variables

| Variable | Type | Description | Default | Required |
|----------|------|-------------|---------|----------|
| `release_name` | string | Helm release name | `hello-nginx` | no |
| `namespace` | string | Kubernetes namespace | `default` | no |
| `create_namespace` | bool | Create namespace if missing | `true` | no |
| `chart_version` | string | nginx Helm chart version | `13.2.10` | no |
| `replica_count` | number | Number of replicas | `2` | no |
| `resources` | object | Pod resource limits/requests | See below | no |

### Default Resources

```hcl
resources = {
  limits = {
    cpu    = "100m"
    memory = "128Mi"
  }
  requests = {
    cpu    = "50m"
    memory = "64Mi"
  }
}
```

## Output Values

| Output | Type | Description |
|--------|------|-------------|
| `release_name` | string | Name of the Helm release |
| `release_namespace` | string | Namespace of the deployment |
| `release_status` | string | Status of the Helm release |
| `release_version` | string | Version of the Helm release |

## Usage Examples

### Basic Deployment

```hcl
module "hello_nginx" {
  source = "./modules/helm_app"

  release_name = "hello-nginx"
  namespace    = "default"
}
```

### Production Deployment

```hcl
module "hello_nginx" {
  source = "./modules/helm_app"

  release_name     = "hello-nginx-prod"
  namespace        = "production"
  create_namespace = true
  chart_version    = "13.2.10"
  replica_count    = 5
  
  resources = {
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
    requests = {
      cpu    = "250m"
      memory = "256Mi"
    }
  }
}
```

### Multi-Environment Setup

```hcl
# Development
module "nginx_dev" {
  source = "./modules/helm_app"

  release_name     = "nginx"
  namespace        = "dev"
  create_namespace = true
  replica_count    = 1
  
  resources = {
    limits = {
      cpu    = "50m"
      memory = "64Mi"
    }
    requests = {
      cpu    = "25m"
      memory = "32Mi"
    }
  }
}

# Staging
module "nginx_staging" {
  source = "./modules/helm_app"

  release_name     = "nginx"
  namespace        = "staging"
  create_namespace = true
  replica_count    = 2
  
  resources = {
    limits = {
      cpu    = "100m"
      memory = "128Mi"
    }
    requests = {
      cpu    = "50m"
      memory = "64Mi"
    }
  }
}

# Production
module "nginx_prod" {
  source = "./modules/helm_app"

  release_name     = "nginx"
  namespace        = "production"
  create_namespace = true
  replica_count    = 3
  
  resources = {
    limits = {
      cpu    = "200m"
      memory = "256Mi"
    }
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
  }
}
```

## Provider Configuration

The module requires configured Helm and Kubernetes providers:

```hcl
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
```

## Application Details

### nginx Configuration

The module deploys nginx with a custom configuration:

```nginx
server {
  listen 8080;
  location / {
    return 200 '<html><body><h1>Hello from nginx!</h1></body></html>';
    add_header Content-Type text/html;
  }
}
```

### Service Configuration

- **Type**: LoadBalancer
- **Port**: 80
- **Target Port**: 8080

## Accessing the Application

### Get Service Details

```bash
# Get service information
kubectl get svc -n <namespace> <release_name>-nginx

# Get external IP
kubectl get svc -n <namespace> <release_name>-nginx \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### Test the Application

```bash
# Using curl
curl http://<EXTERNAL_IP>

# Using wget
wget -qO- http://<EXTERNAL_IP>
```

Expected response:
```html
<html><body><h1>Hello from nginx!</h1></body></html>
```

## Customization

### Using Different Charts

While designed for nginx, the module structure can be adapted:

```hcl
resource "helm_release" "app" {
  name       = var.release_name
  namespace  = var.namespace
  chart      = var.chart_name
  repository = var.chart_repository
  version    = var.chart_version
  
  values = var.custom_values
}
```

### Custom Values File

For complex configurations, use a values file:

```hcl
resource "helm_release" "hello_nginx" {
  # ... other configuration
  
  values = [
    file("${path.module}/values.yaml")
  ]
}
```

## Best Practices

### Resource Management

!!! tip "Resource Sizing"
    Always set appropriate resource limits and requests:
    
    - Start with minimal resources
    - Monitor actual usage
    - Adjust based on metrics
    - Use HPA for auto-scaling

### Namespace Organization

```
namespaces/
├── default        # System components
├── development    # Dev environment
├── staging        # Staging environment
├── production     # Production environment
└── monitoring     # Observability stack
```

### Version Pinning

Always pin chart versions for reproducibility:

```hcl
chart_version = "13.2.10"  # Specific version
# NOT: chart_version = "latest"
```

## Troubleshooting

### Common Issues

**Release Already Exists**
```bash
helm list -n <namespace>
helm delete <release_name> -n <namespace>
```

**Namespace Issues**
```bash
kubectl get namespace
kubectl create namespace <namespace>
```

**Pod Not Starting**
```bash
kubectl describe pod -n <namespace> <pod_name>
kubectl logs -n <namespace> <pod_name>
```

**Service Not Accessible**
```bash
# Check service endpoints
kubectl get endpoints -n <namespace>

# Check pod readiness
kubectl get pods -n <namespace>

# Check firewall rules
gcloud compute firewall-rules list
```

## Performance Tuning

### Horizontal Scaling

```hcl
replica_count = 5  # Increase replicas
```

### Vertical Scaling

```hcl
resources = {
  limits = {
    cpu    = "1000m"
    memory = "1Gi"
  }
  requests = {
    cpu    = "500m"
    memory = "512Mi"
  }
}
```

## Related Documentation

- [GKE Module](gke.md)
- [Architecture Overview](../architecture.md)
- [Development Example](../examples/dev.md)