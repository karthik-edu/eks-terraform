# Real-World Configuration Examples

This document provides copy-paste ready configurations for common scenarios.

## Example 1: Development Cluster (Minimal, Cost-Optimized)

**Use Case**: Local development, experimenting with Kubernetes

**terraform.tfvars**
```hcl
aws_region     = "us-east-1"
aws_profile    = "default"
project_name   = "myapp"
environment    = "dev"

vpc_cidr_block          = "10.0.0.0/16"
availability_zone_count = 1              # Single AZ for cost
private_subnet_count    = 1
public_subnet_count     = 1

cluster_name       = "eks"
kubernetes_version = "1.28"
endpoint_public_access = true
public_access_cidrs    = ["0.0.0.0/0"]   # Your IP in production
enabled_cluster_log_types = ["api"]      # Only essential logs

node_desired_size       = 1
node_min_size          = 1
node_max_size          = 2
node_instance_types    = ["t3.small"]    # Smallest instance
node_capacity_type     = "SPOT"          # ~70% cheaper
node_disk_size         = 20

enable_node_ssh = false

common_tags = {
  ManagedBy   = "Terraform"
  Environment = "Development"
  Owner       = "DevOps"
}
```

**Expected Costs**: ~$20-30/month

**Key Features**:
- Single AZ (no HA)
- SPOT instance (interruptible)
- Minimal logging
- Small instance type
- Perfect for dev/testing

---

## Example 2: Staging Cluster (HA, Production-Like)

**Use Case**: Pre-production testing, similar to production setup

**terraform.tfvars**
```hcl
aws_region  = "us-east-1"
aws_profile = "default"
project_name = "myapp"
environment = "staging"

vpc_cidr_block          = "10.0.0.0/16"
availability_zone_count = 2              # Multi-AZ HA
private_subnet_count    = 2
public_subnet_count     = 2

cluster_name       = "eks"
kubernetes_version = "1.28"
endpoint_private_access = true
endpoint_public_access  = true
public_access_cidrs     = ["203.0.113.0/32"]  # Your office IP
enabled_cluster_log_types = ["api", "audit"]

node_desired_size       = 2
node_min_size          = 2
node_max_size          = 5
node_instance_types    = ["t3.medium"]
node_capacity_type     = "ON_DEMAND"     # More stable
node_disk_size         = 30

node_labels = {
  Environment = "staging"
  Team        = "platform"
}

enable_node_ssh = false

common_tags = {
  ManagedBy   = "Terraform"
  Environment = "Staging"
  Owner       = "DevOps"
  CostCenter  = "Engineering"
}
```

**Expected Costs**: ~$100-150/month

**Key Features**:
- Multi-AZ (high availability)
- ON_DEMAND capacity (stable)
- Proper logging
- Suitable for production simulation
- Medium instance type

---

## Example 3: Production Cluster (Highly Available, Secure)

**Use Case**: Production workloads requiring reliability and security

**terraform.tfvars**
```hcl
aws_region  = "us-east-1"
aws_profile = "prod"               # Separate AWS account/profile
project_name = "myapp"
environment = "prod"

vpc_cidr_block          = "10.0.0.0/16"
availability_zone_count = 3              # Maximum HA
private_subnet_count    = 3
public_subnet_count     = 3

cluster_name       = "eks"
kubernetes_version = "1.28"
endpoint_private_access = true
endpoint_public_access  = false          # Private only
public_access_cidrs     = []
enabled_cluster_log_types = [            # All logs
  "api",
  "audit",
  "authenticator",
  "controllerManager",
  "scheduler"
]
log_retention_days = 30                  # 30 days retention

# General purpose node group
node_desired_size       = 3
node_min_size          = 3
node_max_size          = 10
node_instance_types    = ["t3.large", "t3a.large"]  # Diverse
node_capacity_type     = "ON_DEMAND"
node_disk_size         = 100             # Large disks

node_labels = {
  Environment  = "production"
  Team         = "platform"
  Workload     = "general"
  CostCenter   = "Operations"
}

enable_node_remote_access = true         # For troubleshooting
node_ssh_key_name        = "prod-key"
enable_node_ssh          = true
node_ssh_cidr            = "10.0.0.0/8"  # VPN only

common_tags = {
  ManagedBy   = "Terraform"
  Environment = "Production"
  Owner       = "DevOps"
  CostCenter  = "Operations"
  Compliance  = "PCI-DSS"
}
```

**Expected Costs**: ~$300-500/month (base cluster + workloads)

**Key Features**:
- Full HA (3 AZs)
- Private API endpoint only
- Comprehensive logging
- Large instances
- SSH access for operations
- Multiple workload node groups (add separately)

---

## Example 4: GPU Cluster for ML Workloads

**Use Case**: Machine learning model training

**Root terraform.tfvars** (base config):
```hcl
aws_region     = "us-east-1"
aws_profile    = "default"
project_name   = "ml-platform"
environment    = "prod"

vpc_cidr_block          = "10.0.0.0/16"
availability_zone_count = 2
private_subnet_count    = 2
public_subnet_count     = 2

cluster_name       = "eks"
kubernetes_version = "1.28"
endpoint_private_access = true
endpoint_public_access  = false
enabled_cluster_log_types = ["api", "audit"]
```

**Extend main.tf with GPU node group**:
```hcl
# General node group (existing)
module "node_group_general" {
  source = "./modules/node_group"
  
  cluster_name = module.eks_cluster.cluster_name
  # ... standard config
  
  instance_types = ["t3.medium"]
  capacity_type  = "ON_DEMAND"
  
  labels = {
    workload_type = "general"
  }
}

# GPU node group (new)
module "node_group_gpu" {
  source = "./modules/node_group"
  
  cluster_name = module.eks_cluster.cluster_name
  cluster_name_prefix = local.name_prefix
  node_group_iam_role_arn = module.iam.node_group_iam_role_arn
  private_subnet_ids = module.vpc.private_subnet_ids
  
  instance_types = ["g4dn.xlarge"]      # 1 T4 GPU
  capacity_type  = "SPOT"               # ~70% savings on GPU
  disk_size      = 100
  
  desired_size = 0                       # Start empty, scale up on demand
  min_size     = 0
  max_size     = 5
  
  labels = {
    workload_type = "gpu"
    gpu_type      = "t4"
  }
  
  taints = [{
    key    = "gpu"
    value  = "true"
    effect = "NoSchedule"               # Only scheduled pods tolerate
  }]
  
  base_tags = local.base_tags
}
```

**Key Configuration**:
- 2 different instance types for different workloads
- GPU nodes with SPOT pricing
- Taints ensure only GPU workloads run on GPU nodes
- Auto-scale from 0 for cost savings
- Separate node group for general control plane traffic

---

## Example 5: Multi-Region Cluster (Global HA)

**Directory Structure**:
```
terraform-eks/
├── modules/
│   ├── vpc/
│   ├── iam/
│   └── ...
├── us-east-1/
│   ├── main.tf
│   └── terraform.tfvars
├── us-west-2/
│   ├── main.tf
│   └── terraform.tfvars
└── eu-west-1/
    ├── main.tf
    └── terraform.tfvars
```

**us-east-1/terraform.tfvars**:
```hcl
aws_region  = "us-east-1"
project_name = "global-app"
environment = "prod"
# ... rest of config
```

**us-west-2/terraform.tfvars**:
```hcl
aws_region  = "us-west-2"               # Different region
project_name = "global-app"
environment = "prod"
vpc_cidr_block = "10.1.0.0/16"          # Different CIDR per region!
# ... rest of config
```

**Deploy**:
```bash
cd us-east-1
terraform init
terraform apply -var-file=terraform.tfvars

cd ../us-west-2
terraform init
terraform apply -var-file=terraform.tfvars
```

**Result**: Independent clusters in multiple regions for true global HA

---

## Example 6: Hybrid Private + Public Node Groups

**Use Case**: Workloads with different security requirements

**In main.tf**:
```hcl
# Public-facing applications
module "node_group_public" {
  source = "./modules/node_group"
  
  cluster_name = module.eks_cluster.cluster_name
  # ... config
  
  labels = {
    workload_type = "public-app"
  }
  
  # No taints - any pod can schedule
}

# Highly sensitive workloads
module "node_group_private" {
  source = "./modules/node_group"
  
  cluster_name = module.eks_cluster.cluster_name
  # ... config
  
  instance_types = ["m5.large"]  # Larger, more secure
  
  labels = {
    workload_type = "private-app"
    security_level = "high"
  }
  
  taints = [{
    key    = "security"
    value  = "restricted"
    effect = "NoSchedule"
  }]
}

# Cost-optimized (non-critical)
module "node_group_spot" {
  source = "./modules/node_group"
  
  cluster_name = module.eks_cluster.cluster_name
  # ... config
  
  capacity_type  = "SPOT"
  desired_size   = 2
  max_size       = 10
  
  labels = {
    workload_type = "batch-jobs"
  }
  
  taints = [{
    key    = "capacity"
    value  = "spot"
    effect = "NoSchedule"
  }]
}
```

---

## Example 7: Compliance & Security Hardened Cluster

**terraform.tfvars**:
```hcl
aws_region  = "us-east-1"
aws_profile = "compliance"
project_name = "secure-platform"
environment = "prod"

# Network isolation
vpc_cidr_block          = "10.0.0.0/16"
availability_zone_count = 3              # Maximum HA
private_subnet_count    = 3              # Nodes in private subnets only
public_subnet_count     = 0              # No public nodes!

cluster_name       = "eks"
kubernetes_version = "1.28"

# API endpoint: Private only (no public internet exposure)
endpoint_private_access = true
endpoint_public_access  = false
public_access_cidrs     = []

# Comprehensive logging for compliance
enabled_cluster_log_types = [
  "api",
  "audit",
  "authenticator",
  "controllerManager",
  "scheduler"
]
log_retention_days = 90                 # Compliance retention

# Node configuration
node_desired_size       = 3
node_min_size          = 3               # Always min 3 for HA
node_max_size          = 10
node_instance_types    = ["m5.large"]
node_capacity_type     = "ON_DEMAND"     # Predictable
node_disk_size         = 200             # Large for audit logs

# SSH strictly controlled
enable_node_remote_access = true
node_ssh_key_name        = "compliance-key"
enable_node_ssh          = true
node_ssh_cidr            = "10.0.10.0/24" # Bastion subnet only

node_labels = {
  Environment = "production"
  Compliance  = "SOC2"
  Team        = "security"
}

common_tags = {
  ManagedBy   = "Terraform"
  Environment = "Production"
  Compliance  = "SOC2"
  Owner       = "SecurityTeam"
  CostCenter  = "Operations"
  EncryptionRequired = "Yes"
  BackupRequired     = "Yes"
}
```

---

## Deployment Checklist for Each Example

### Before `terraform apply`:

```bash
# 1. Validate configuration
terraform validate

# 2. Format code
terraform fmt -recursive

# 3. Check what will be created
terraform plan | grep "aws_" | wc -l

# 4. Review specific resources
terraform plan | grep -E "(security_group|iam_role|instance)"

# 5. Estimate costs (with Infracost)
infracost breakdown --path .

# 6. Security scan
tfsec .

# 7. Policy compliance
checkov -d .

# 8. Review output plan file
terraform plan -out=tfplan
cat tfplan | less

# 9. Apply only if confident
terraform apply tfplan
```

---

## Cost Comparison Summary

| Configuration | Monthly Cost | Use Case |
|--------------|------------|----------|
| Development | $20-30 | Dev/Test |
| Staging | $100-150 | Pre-prod |
| Production | $300-500+ | Production |
| GPU ML | $500-1000+ | ML Training |
| Multi-Region | $600-1500+ | Global HA |

---

## Next Steps After Deployment

1. **Deploy applications**: `kubectl apply -f app.yaml`
2. **Setup ingress**: Install AWS Load Balancer Controller
3. **Enable monitoring**: Deploy Prometheus + Grafana
4. **Configure autoscaling**: Deploy Cluster Autoscaler
5. **Setup CICD**: Deploy ArgoCD or Flux
6. **Enable backups**: Install backup solution

Use these configurations as starting points and adapt to your needs!
