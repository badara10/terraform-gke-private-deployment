# Development Environment Example

This example demonstrates a complete deployment of a private GKE cluster with a hello-nginx application.

## Overview

This configuration provisions:
- A new VPC network with subnet
- A private GKE cluster with 3 nodes
- Service accounts with minimal required permissions
- The hello-nginx application deployed via Helm
- All required Google Cloud APIs

## Prerequisites

1. **GCP Project**: An active Google Cloud project
2. **Service Account Key**: A service account with required permissions
3. **Terraform**: Version 1.0 or higher
4. **gcloud CLI**: For kubectl configuration

## Quick Start

1. **Clone and navigate to the example**:
   ```bash
   cd examples/dev
   ```

2. **Update credentials** (if needed):
   Edit `variables.tf` or create `terraform.tfvars`:
   ```hcl
   credentials_file = "/path/to/your/credentials.json"
   project_id       = "your-project-id"
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Review the plan**:
   ```bash
   terraform plan
   ```

5. **Deploy the infrastructure**:
   ```bash
   terraform apply
   ```

6. **Configure kubectl**:
   ```bash
   gcloud container clusters get-credentials private-gke-cluster \
     --region us-central1 \
     --project your-project-id
   ```

7. **Verify deployment**:
   ```bash
   kubectl get namespaces
   kubectl get pods -n hello-app
   kubectl get svc -n hello-app
   ```

## Configuration

### Default Values

| Variable | Default | Description |
|----------|---------|-------------|
| project_id | crucial-respect-470815-u3 | GCP project ID |
| region | us-central1 | GCP region |
| cluster_name | private-gke-cluster | Name of the GKE cluster |
| node_count | 3 | Number of nodes |
| machine_type | e2-medium | Instance type for nodes |
| create_vpc | true | Create new VPC or use existing |

### Using terraform.tfvars

Create a `terraform.tfvars` file to override defaults:

```hcl
credentials_file = "/home/user/gcp-credentials.json"
project_id       = "my-project-id"
region           = "europe-west1"
cluster_name     = "my-cluster"
node_count       = 5
machine_type     = "n2-standard-2"
preemptible      = true
```

## Network Architecture

The example uses the 10.1.2.0/18 IP block with the following allocation:

| Range | CIDR | Purpose | IPs |
|-------|------|---------|-----|
| Nodes | 10.1.2.0/24 | GKE node IPs | 256 |
| Pods | 10.1.4.0/22 | Pod networking | 1024 |
| Services | 10.1.8.0/22 | Kubernetes services | 1024 |
| Master | 10.1.0.0/28 | Control plane | 16 |

## File Structure

```
examples/dev/
├── main.tf               # Main configuration
├── variables.tf          # Input variables
├── outputs.tf           # Output values
├── versions.tf          # Provider versions
├── apis.tf              # API enablement
├── terraform.tfvars.example  # Example variables file
└── README.md            # This file
```

## Components

### APIs Enabled
- Compute Engine API
- Kubernetes Engine API
- Identity and Access Management API
- Cloud Resource Manager API

### Resources Created
1. **Network Resources**:
   - VPC network (gke-vpc)
   - Subnet with secondary ranges
   - Private Google Access enabled

2. **IAM Resources**:
   - Service account for nodes
   - IAM bindings for logging and monitoring

3. **GKE Resources**:
   - Private GKE cluster
   - Node pool with auto-repair and auto-upgrade
   - Workload Identity enabled

4. **Application Resources**:
   - Kubernetes namespace (hello-app)
   - Helm release (hello-nginx)
   - LoadBalancer service

## Outputs

After successful deployment, Terraform outputs:

- `cluster_name`: Name of the created cluster
- `cluster_endpoint`: Cluster API endpoint (sensitive)
- `cluster_region`: Cluster region
- `hello_nginx_release_name`: Helm release name
- `hello_nginx_namespace`: Application namespace
- `kubectl_config_command`: Command to configure kubectl

## Accessing the Application

1. **Get the LoadBalancer IP**:
   ```bash
   kubectl get svc -n hello-app hello-nginx
   ```

2. **Test the application**:
   ```bash
   curl http://<EXTERNAL_IP>
   ```

   Expected response:
   ```html
   <html><body><h1>Hello from nginx!</h1></body></html>
   ```

## Security Considerations

- **Private Nodes**: All nodes have only private IP addresses
- **Master Authorized Networks**: Currently set to 0.0.0.0/0 for development. **Restrict in production!**
- **Service Account**: Nodes use a dedicated service account with minimal permissions
- **Workload Identity**: Enabled for secure pod-to-GCP authentication
- **Network Policies**: Enabled for pod-to-pod communication control

## Customization

### Using Existing VPC

Set `create_vpc = false` and provide existing network names:

```hcl
create_vpc  = false
vpc_name    = "existing-vpc"
subnet_name = "existing-subnet"
```

### Adjusting Node Pool

```hcl
node_count   = 5
machine_type = "n2-standard-4"
preemptible  = true
```

### Restricting Master Access

For production, restrict master authorized networks:

```hcl
master_authorized_networks = [
  {
    cidr_block   = "203.0.113.0/24"  # Your office IP range
    display_name = "office"
  },
  {
    cidr_block   = "10.0.0.0/8"      # Internal networks
    display_name = "internal"
  }
]
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Note**: The cluster has deletion protection enabled by default. You may need to manually remove this protection or delete the cluster via the console if Terraform destroy fails.

## Troubleshooting

### API Not Enabled
If you encounter API errors, ensure all required APIs are enabled:
```bash
gcloud services enable compute.googleapis.com \
  container.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com \
  --project=your-project-id
```

### Insufficient Permissions
Ensure your service account has these roles:
- Kubernetes Engine Admin
- Compute Admin
- Service Account Admin
- Project IAM Admin

### Quota Errors
Check your project quotas:
```bash
gcloud compute project-info describe --project=your-project-id
```

## Cost Optimization

For development/testing, consider:
- Using preemptible nodes (`preemptible = true`)
- Reducing node count (`node_count = 1`)
- Using smaller machine types (`machine_type = "e2-micro"`)
- Destroying resources when not in use