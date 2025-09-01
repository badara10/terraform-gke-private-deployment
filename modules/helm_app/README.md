# Helm Application Module

This module deploys a hello-nginx application to Kubernetes using Helm.

## Purpose

Deploys a customized nginx application via Helm with:
- Configurable namespace management
- Custom "Hello from nginx!" response
- LoadBalancer service exposing port 80
- Resource limits and replica configuration
- Support for custom Helm values

## Usage Examples

### Basic Deployment

```hcl
module "hello_nginx" {
  source = "../../modules/helm_app"

  release_name     = "hello-nginx"
  namespace        = "default"
  create_namespace = false
}
```

### Production Deployment with Custom Configuration

```hcl
module "hello_nginx" {
  source = "../../modules/helm_app"

  release_name     = "hello-nginx-prod"
  namespace        = "production"
  create_namespace = true
  chart_version    = "13.2.10"
  replica_count    = 5
  
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

### Multiple Environment Deployment

```hcl
# Development environment
module "hello_nginx_dev" {
  source = "../../modules/helm_app"

  release_name     = "hello-nginx"
  namespace        = "development"
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

# Staging environment
module "hello_nginx_staging" {
  source = "../../modules/helm_app"

  release_name     = "hello-nginx"
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

# Production environment
module "hello_nginx_prod" {
  source = "../../modules/helm_app"

  release_name     = "hello-nginx"
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

## Module Composition with GKE

```hcl
# Deploy GKE cluster first
module "gke" {
  source = "./modules/gke"
  # ... GKE configuration
}

# Configure Helm provider
provider "helm" {
  kubernetes = {
    host                   = "https://${module.gke.cluster_endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
  }
}

# Deploy application
module "hello_nginx" {
  source = "./modules/helm_app"

  release_name     = "hello-nginx"
  namespace        = "apps"
  create_namespace = true
  replica_count    = 2
  
  depends_on = [module.gke]
}
```

## Requirements

- Terraform >= 1.0
- Helm Provider >= 2.8.0
- Kubernetes Provider >= 2.16.0
- Access to a Kubernetes cluster

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| release_name | The name of the Helm release | `string` | `"hello-nginx"` | no |
| namespace | The Kubernetes namespace to deploy the application | `string` | `"default"` | no |
| create_namespace | Whether to create the namespace if it doesn't exist | `bool` | `true` | no |
| chart_version | The version of the nginx Helm chart | `string` | `"13.2.10"` | no |
| replica_count | Number of nginx replicas | `number` | `2` | no |
| resources | Resource limits and requests for the pods | `object` | See below | no |

### Default Resources

```hcl
{
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

## Outputs

| Name | Description |
|------|-------------|
| release_name | The name of the Helm release |
| release_namespace | The namespace of the Helm release |
| release_status | The status of the Helm release |
| release_version | The version of the Helm release |

## Application Details

The module deploys an nginx server configured with:

- **Custom Response**: Returns a simple HTML page with "Hello from nginx!"
- **Service Type**: LoadBalancer exposing port 80
- **Listen Port**: nginx listens on port 8080 internally
- **Chart Source**: Bitnami nginx chart from https://charts.bitnami.com/bitnami

## Accessing the Application

After deployment, you can access the application by:

1. Get the LoadBalancer IP:
   ```bash
   kubectl get svc -n <namespace> <release_name>-nginx
   ```

2. Access the application:
   ```bash
   curl http://<EXTERNAL_IP>
   ```

3. Expected response:
   ```html
   <html><body><h1>Hello from nginx!</h1></body></html>
   ```

## Customization

To customize the nginx configuration, modify the `serverBlock` in the module's main.tf:

```hcl
serverBlock = <<-EOT
  server {
    listen 8080;
    location / {
      return 200 '<html><body><h1>Your Custom Message</h1></body></html>';
      add_header Content-Type text/html;
    }
  }
EOT
```

## Notes

- The module uses the Bitnami nginx Helm chart
- The namespace will be created automatically if `create_namespace = true`
- The service is exposed as LoadBalancer by default
- Resource limits help ensure cluster stability