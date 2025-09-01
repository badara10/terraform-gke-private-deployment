# Architecture Documentation

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Google Cloud Project                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │                    VPC Network                      │     │
│  │                   (10.1.2.0/18)                    │     │
│  ├────────────────────────────────────────────────────┤     │
│  │                                                    │     │
│  │  ┌──────────────────────────────────────────┐     │     │
│  │  │         GKE Master Control Plane         │     │     │
│  │  │            (10.1.0.0/28)                │     │     │
│  │  └──────────────────────────────────────────┘     │     │
│  │                        │                           │     │
│  │  ┌──────────────────────────────────────────┐     │     │
│  │  │           Private Node Pool              │     │     │
│  │  │            (10.1.2.0/24)                │     │     │
│  │  │  ┌────────┐  ┌────────┐  ┌────────┐    │     │     │
│  │  │  │ Node 1 │  │ Node 2 │  │ Node 3 │    │     │     │
│  │  │  └────────┘  └────────┘  └────────┘    │     │     │
│  │  └──────────────────────────────────────────┘     │     │
│  │                                                    │     │
│  │  ┌──────────────────────────────────────────┐     │     │
│  │  │         Pod Network Range                │     │     │
│  │  │          (10.1.4.0/22)                  │     │     │
│  │  │  ┌─────────────────────────────────┐    │     │     │
│  │  │  │    hello-nginx pods (replicas)  │    │     │     │
│  │  │  └─────────────────────────────────┘    │     │     │
│  │  └──────────────────────────────────────────┘     │     │
│  │                                                    │     │
│  │  ┌──────────────────────────────────────────┐     │     │
│  │  │       Service Network Range              │     │     │
│  │  │         (10.1.8.0/22)                   │     │     │
│  │  │  ┌─────────────────────────────────┐    │     │     │
│  │  │  │  LoadBalancer Service (port 80) │    │     │     │
│  │  │  └─────────────────────────────────┘    │     │     │
│  │  └──────────────────────────────────────────┘     │     │
│  └────────────────────────────────────────────────────┘     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Component Architecture

### 1. Infrastructure Layer (GKE Module)

```
modules/gke/
├── main.tf              # Cluster and node pool resources
├── variables.tf         # Input variables
├── outputs.tf          # Output values
├── versions.tf         # Provider requirements
└── README.md           # Module documentation
```

**Key Components**:
- **google_container_cluster**: Private GKE cluster configuration
- **google_container_node_pool**: Managed node pool with auto-scaling
- **Network Configuration**: Private nodes, secondary ranges
- **Security Features**: Workload identity, network policies

### 2. Application Layer (Helm Module)

```
modules/helm_app/
├── main.tf              # Helm release and namespace
├── variables.tf         # Input variables
├── outputs.tf          # Output values
├── versions.tf         # Provider requirements
└── README.md           # Module documentation
```

**Key Components**:
- **kubernetes_namespace**: Optional namespace creation
- **helm_release**: nginx deployment via Helm
- **Service Configuration**: LoadBalancer on port 80

### 3. Composition Layer (Examples)

```
examples/dev/
├── main.tf              # Module composition
├── variables.tf         # Environment variables
├── outputs.tf          # Environment outputs
├── versions.tf         # Provider versions
├── apis.tf             # API enablement
├── terraform.tfvars.example  # Example configuration
└── README.md           # Environment documentation
```

## Data Flow

```
User Request → LoadBalancer Service (10.1.8.0/22)
                       ↓
              nginx Pods (10.1.4.0/22)
                       ↓
              Private Nodes (10.1.2.0/24)
                       ↓
              GKE Control Plane (10.1.0.0/28)
```

## Security Architecture

### Network Security
- **Private Nodes**: No public IP addresses
- **Private Google Access**: Enabled for GCP service access
- **Master Authorized Networks**: Configurable IP allowlist
- **Network Policies**: Pod-to-pod communication control

### Identity & Access
- **Workload Identity**: Pods authenticate as Google service accounts
- **Service Accounts**: Minimal permissions per principle of least privilege
- **RBAC**: Kubernetes role-based access control

### Data Protection
- **Encryption at Rest**: GKE automatic encryption
- **Encryption in Transit**: TLS for all communications
- **Shielded Nodes**: Secure boot and integrity monitoring

## Module Interfaces

### GKE Module Interface

**Inputs**:
- Network configuration (VPC, subnet, ranges)
- Cluster configuration (name, region, node count)
- Security settings (authorized networks, service account)

**Outputs**:
- Cluster endpoint and credentials
- Network references
- Cluster metadata

### Helm Module Interface

**Inputs**:
- Release configuration (name, namespace)
- Application settings (replicas, resources)
- Chart configuration (version, values)

**Outputs**:
- Release status and metadata
- Service endpoints
- Application namespace

## Deployment Flow

1. **API Enablement**: Enable required Google Cloud APIs
2. **Network Creation**: Provision VPC and subnets (if needed)
3. **IAM Setup**: Create service accounts and bindings
4. **Cluster Provisioning**: Deploy GKE cluster
5. **Node Pool Creation**: Add managed node pool
6. **Provider Configuration**: Configure Kubernetes/Helm providers
7. **Application Deployment**: Install nginx via Helm
8. **Service Exposure**: Create LoadBalancer service

## Scalability Considerations

### Horizontal Scaling
- **Nodes**: Auto-scaling based on resource demands
- **Pods**: HPA (Horizontal Pod Autoscaler) capable
- **IP Space**: Sufficient allocation for growth

### Vertical Scaling
- **Node Types**: Configurable machine types
- **Resource Limits**: Adjustable pod resources
- **Cluster Size**: Can scale to hundreds of nodes

## Monitoring & Observability

### Built-in Monitoring
- GKE monitoring with Cloud Monitoring
- Container logs in Cloud Logging
- Metrics collection for nodes and pods

### Health Checks
- Liveness probes for pod health
- Readiness probes for traffic routing
- Node auto-repair for failed nodes

## Disaster Recovery

### Backup Strategy
- Terraform state versioning
- GKE backup capabilities
- Configuration in version control

### Recovery Procedures
1. Restore from Terraform state
2. Recreate cluster from code
3. Redeploy applications via Helm
4. Verify service connectivity

## Cost Optimization

### Resource Efficiency
- Preemptible nodes for non-critical workloads
- Right-sizing based on actual usage
- Cluster autoscaling to match demand

### Network Costs
- Private connectivity reduces egress
- Regional resources minimize cross-zone traffic
- Efficient IP allocation reduces waste