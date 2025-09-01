# Deployment Guide

## Prerequisites

Before deploying, ensure you have:

1. **Google Cloud Account**
   - Active GCP project
   - Billing enabled
   - Project ID noted

2. **Service Account**
   - Created with appropriate permissions
   - Key file downloaded (JSON format)

3. **Required Tools**
   - Terraform >= 1.0
   - Google Cloud SDK (gcloud)
   - kubectl
   - Helm (optional)

## Step-by-Step Deployment

### Step 1: Clone Repository

```bash
git clone https://github.com/badara10/terraform-gke-private-deployment.git
cd terraform-gke-private-deployment
```

### Step 2: Configure Authentication

#### Option A: Service Account Key

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/credentials.json"
```

#### Option B: gcloud Authentication

```bash
gcloud auth application-default login
gcloud config set project your-project-id
```

### Step 3: Configure Variables

```bash
cd examples/dev
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
credentials_file = "/path/to/your/credentials.json"
project_id       = "your-project-id"
region           = "us-central1"
cluster_name     = "private-gke-cluster"
node_count       = 3
machine_type     = "e2-medium"
preemptible      = false
```

### Step 4: Initialize Terraform

```bash
terraform init
```

Expected output:
```
Initializing modules...
- gke in ../../modules/gke
- hello_nginx in ../../modules/helm_app

Initializing provider plugins...
...
Terraform has been successfully initialized!
```

### Step 5: Review Plan

```bash
terraform plan
```

Review the resources to be created:
- Google Cloud APIs (4)
- VPC and subnet (2)
- Service account and IAM (4)
- GKE cluster and node pool (2)
- Kubernetes namespace (1)
- Helm release (1)

### Step 6: Deploy Infrastructure

```bash
terraform apply
```

When prompted:
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

!!! note "Deployment Time"
    The deployment typically takes 8-10 minutes:
    - API enablement: 1-2 minutes
    - Network creation: 30 seconds
    - GKE cluster: 5-7 minutes
    - Application deployment: 1-2 minutes

### Step 7: Configure kubectl

```bash
# Get credentials
gcloud container clusters get-credentials private-gke-cluster \
  --region us-central1 \
  --project your-project-id

# Verify connection
kubectl cluster-info
```

### Step 8: Verify Deployment

```bash
# Check nodes
kubectl get nodes

# Check application
kubectl get pods -n hello-app
kubectl get svc -n hello-app

# Get external IP
EXTERNAL_IP=$(kubectl get svc -n hello-app hello-nginx \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Application URL: http://$EXTERNAL_IP"
```

### Step 9: Test Application

```bash
curl http://$EXTERNAL_IP
```

Expected response:
```html
<html><body><h1>Hello from nginx!</h1></body></html>
```

## Environment-Specific Deployments

### Development Environment

```hcl
# terraform.tfvars
environment  = "dev"
node_count   = 1
machine_type = "e2-micro"
preemptible  = true
```

### Staging Environment

```hcl
# terraform.tfvars
environment  = "staging"
node_count   = 2
machine_type = "e2-small"
preemptible  = true
```

### Production Environment

```hcl
# terraform.tfvars
environment  = "production"
node_count   = 5
machine_type = "n2-standard-4"
preemptible  = false

# Additional security
enable_private_endpoint = true
master_authorized_networks = [
  {
    cidr_block   = "203.0.113.0/24"
    display_name = "office"
  }
]
```

## Advanced Configuration

### Using Remote State

```hcl
# backend.tf
terraform {
  backend "gcs" {
    bucket = "my-terraform-state"
    prefix = "gke/dev"
  }
}
```

### Enabling Additional Features

```hcl
# Enable binary authorization
binary_authorization_enabled = true

# Enable network policy
network_policy_enabled = true

# Enable pod security policy
pod_security_policy_enabled = true
```

### Custom Node Pools

```hcl
# Additional node pool for GPU workloads
resource "google_container_node_pool" "gpu_pool" {
  name       = "gpu-pool"
  cluster    = module.gke.cluster_name
  node_count = 1

  node_config {
    machine_type = "n1-standard-4"
    
    guest_accelerator {
      type  = "nvidia-tesla-k80"
      count = 1
    }
  }
}
```

## Monitoring and Logging

### Enable GKE Monitoring

```hcl
# In GKE module
monitoring_service = "monitoring.googleapis.com/kubernetes"
logging_service    = "logging.googleapis.com/kubernetes"
```

### View Logs

```bash
# Pod logs
kubectl logs -n hello-app -l app=nginx

# Node logs
gcloud logging read "resource.type=gke_node_pool"
```

### View Metrics

```bash
# In Google Cloud Console
# Kubernetes Engine > Workloads > hello-nginx
# View metrics and logs
```

## Troubleshooting Deployment

### API Errors

```bash
# If APIs are not enabled
gcloud services enable \
  compute.googleapis.com \
  container.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com \
  --project=your-project-id
```

### Permission Errors

```bash
# Grant required roles
gcloud projects add-iam-policy-binding your-project-id \
  --member="serviceAccount:your-sa@your-project.iam.gserviceaccount.com" \
  --role="roles/container.admin"
```

### Network Issues

```bash
# Check firewall rules
gcloud compute firewall-rules create allow-lb \
  --allow tcp:80 \
  --source-ranges 0.0.0.0/0 \
  --target-tags gke-node
```

### Cluster Access Issues

```bash
# Reset kubeconfig
rm ~/.kube/config
gcloud container clusters get-credentials private-gke-cluster \
  --region us-central1 \
  --project your-project-id

# Test with explicit context
kubectl --context=gke_your-project_us-central1_private-gke-cluster get nodes
```

## Updating Infrastructure

### Update Cluster

```bash
# Modify variables
vim terraform.tfvars

# Plan changes
terraform plan

# Apply changes
terraform apply
```

### Update Application

```bash
# Modify helm module
vim ../../modules/helm_app/main.tf

# Apply changes
terraform apply -target=module.hello_nginx
```

### Rolling Updates

```bash
# Update node pool
terraform apply -target=module.gke.google_container_node_pool.primary_nodes
```

## Destroying Infrastructure

### Complete Teardown

```bash
terraform destroy
```

### Selective Destruction

```bash
# Remove application only
terraform destroy -target=module.hello_nginx

# Remove cluster only
terraform destroy -target=module.gke
```

!!! warning "Deletion Protection"
    If deletion protection is enabled:
    ```bash
    # Disable via gcloud
    gcloud container clusters update private-gke-cluster \
      --no-enable-deletion-protection \
      --region us-central1
    ```

## Best Practices

### Security

1. **Use Private Endpoints**
   ```hcl
   enable_private_endpoint = true
   ```

2. **Restrict Network Access**
   ```hcl
   master_authorized_networks = [
     {
       cidr_block   = "10.0.0.0/8"
       display_name = "internal"
     }
   ]
   ```

3. **Enable Audit Logging**
   ```hcl
   cluster_telemetry_type = "ENABLED"
   ```

### Cost Optimization

1. **Use Preemptible Nodes**
   ```hcl
   preemptible = true
   ```

2. **Right-size Resources**
   ```hcl
   machine_type = "e2-small"  # Start small
   ```

3. **Use Autoscaling**
   ```hcl
   autoscaling {
     min_node_count = 1
     max_node_count = 5
   }
   ```

### Operational Excellence

1. **Use Remote State**
2. **Version Pin Providers**
3. **Tag Resources Appropriately**
4. **Document Changes**
5. **Test in Non-Production First**

## Next Steps

After successful deployment:

1. **Set up monitoring and alerting**
2. **Configure backup and disaster recovery**
3. **Implement CI/CD pipelines**
4. **Add additional security layers**
5. **Optimize for cost and performance**

## Support

For issues or questions:
- Check [GitHub Issues](https://github.com/badara10/terraform-gke-private-deployment/issues)
- Review [module documentation](modules/gke.md)
- Consult [GKE documentation](https://cloud.google.com/kubernetes-engine/docs)