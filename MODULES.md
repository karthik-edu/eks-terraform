# Module Documentation

This document describes each module in the EKS Terraform project.

## Module List

1. [VPC Module](#vpc-module)
2. [Security Module](#security-module)
3. [IAM Module](#iam-module)
4. [EKS Cluster Module](#eks-cluster-module)
5. [Node Group Module](#node-group-module)

---

## VPC Module

**Location**: `modules/vpc/`

**Purpose**: Create VPC network infrastructure with multi-AZ support

### Resources Created
- VPC with DNS enabled
- Internet Gateway
- Private subnets across AZs
- Public subnets across AZs
- NAT Gateway with Elastic IP
- Route tables (public & private)
- Route table associations
- Kubernetes-specific tags for ELB discovery

### Required Variables

```hcl
name_prefix              # Resource naming prefix
vpc_cidr_block          # VPC CIDR block (e.g., 10.0.0.0/16)
availability_zones      # List of AZ names
private_subnet_count    # Number of private subnets
public_subnet_count     # Number of public subnets
```

### Optional Variables

```hcl
base_tags = map(string)  # Tags for all resources
```

### Outputs

```hcl
vpc_id                  # VPC identifier
vpc_cidr_block         # VPC CIDR block
private_subnet_ids     # List of private subnet IDs
public_subnet_ids      # List of public subnet IDs
nat_gateway_id         # NAT Gateway ID
nat_gateway_public_ip  # NAT Gateway Elastic IP
internet_gateway_id    # Internet Gateway ID
```

### Usage Example

```hcl
module "vpc" {
  source = "./modules/vpc"
  
  name_prefix         = "myapp-dev"
  vpc_cidr_block      = "10.0.0.0/16"
  availability_zones  = ["us-east-1a", "us-east-1b"]
  private_subnet_count = 2
  public_subnet_count = 2
  
  base_tags = {
    Environment = "dev"
    Project     = "myapp"
  }
}
```

### Network Design

```
VPC (10.0.0.0/16)
├── Public Subnets (with IGW)
│   ├── us-east-1a: 10.0.4.0/20 (NAT Gateway here)
│   └── us-east-1b: 10.0.5.0/20
├── Private Subnets (with NAT)
│   ├── us-east-1a: 10.0.0.0/20
│   └── us-east-1b: 10.0.1.0/20
└── Internet Gateway
```

---

## Security Module

**Location**: `modules/security/`

**Purpose**: Manage EKS security groups and network access

### Resources Created
- Cluster security group with ingress/egress rules
- Node security group with ingress/egress rules
- Rules for node-to-cluster communication
- Rules for pod-to-pod communication
- Optional SSH access rule

### Required Variables

```hcl
name_prefix  # Resource naming prefix
vpc_id       # VPC ID (from vpc module)
```

### Optional Variables

```hcl
base_tags           = map(string)  # Tags for resources
enable_ssh_access   = bool         # Enable SSH (default: false)
ssh_cidr_block      = string       # SSH source CIDR (default: 10.0.0.0/8)
```

### Outputs

```hcl
cluster_security_group_id  # Cluster security group ID
node_security_group_id     # Node security group ID
```

### Security Rules Reference

| Rule | Direction | Protocol | Port | Source | Purpose |
|------|-----------|----------|------|--------|---------|
| Node→Cluster | Ingress | TCP | 443 | Node SG | API communication |
| Cluster→Node | Ingress | TCP | 10250 | Cluster SG | Kubelet API |
| Node→Node | Ingress | TCP | 0-65535 | Node SG | Pod communication |
| Pod→Pod | Ingress | All | All | Node SG | CNI plugin |
| SSH (opt) | Ingress | TCP | 22 | SSH CIDR | Remote access |
| All | Egress | All | All | 0.0.0.0/0 | Outbound internet |

### Usage Example

```hcl
module "security" {
  source = "./modules/security"
  
  name_prefix       = "myapp-dev"
  vpc_id            = module.vpc.vpc_id
  enable_ssh_access = true
  ssh_cidr_block    = "203.0.113.0/24"  # Your corporate IP
  
  base_tags = {
    Environment = "dev"
  }
}
```

---

## IAM Module

**Location**: `modules/iam/`

**Purpose**: Create IAM roles and setup IRSA (IAM Roles for Service Accounts)

### Resources Created
- EKS cluster IAM role with required policies
- EKS node group IAM role with required policies
- OIDC identity provider for IRSA
- Service account assume role policy

### Required Variables

```hcl
name_prefix                  # Resource naming prefix
cluster_oidc_issuer_url     # OIDC issuer URL from EKS cluster
oidc_provider_thumbprint    # TLS certificate thumbprint
```

### Optional Variables

```hcl
base_tags               = map(string)  # Tags for resources
namespace               = string       # K8s namespace (default: default)
service_account_name    = string       # K8s service account name (default: default)
```

### Outputs

```hcl
cluster_iam_role_arn              # Cluster IAM role ARN
cluster_iam_role_name             # Cluster IAM role name
node_group_iam_role_arn           # Node group IAM role ARN
node_group_iam_role_name          # Node group IAM role name
oidc_provider_arn                 # OIDC provider ARN
service_account_assume_role_policy # IRSA assume role policy
```

### Attached Policies

**Cluster Role:**
- AmazonEKSClusterPolicy
- AmazonEKSVPCResourceController

**Node Role:**
- AmazonEKSWorkerNodePolicy
- AmazonEKS_CNI_Policy
- AmazonEC2ContainerRegistryReadOnly
- AmazonSSMManagedInstanceCore
- service-role/AmazonEBSCSIDriverPolicy

### IRSA Usage

To grant Kubernetes service account AWS permissions:

```hcl
# Create assume role policy (output of this module)
policy = module.iam.service_account_assume_role_policy

# Create IAM role with this policy
resource "aws_iam_role" "irsa_example" {
  assume_role_policy = policy
}

# Attach policies to this role
# Then create Kubernetes service account with annotation:
# eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/irsa-example
```

### Usage Example

```hcl
module "iam" {
  source = "./modules/iam"
  
  name_prefix              = "myapp-dev"
  cluster_oidc_issuer_url  = module.eks_cluster.cluster_oidc_issuer_url
  oidc_provider_thumbprint = data.tls_certificate.cluster.certificates[0].sha1_fingerprint
  
  base_tags = {
    Environment = "dev"
  }
}
```

---

## EKS Cluster Module

**Location**: `modules/eks/`

**Purpose**: Deploy and configure EKS cluster control plane

### Resources Created
- EKS cluster with managed control plane
- CloudWatch log group for cluster logs
- API endpoint configuration (private/public)
- Kubernetes add-on support ready

### Required Variables

```hcl
cluster_name              # Cluster name prefix
cluster_name_prefix       # Naming prefix
cluster_iam_role_arn      # Cluster IAM role ARN (from iam module)
private_subnet_ids        # Private subnet IDs (from vpc module)
public_subnet_ids         # Public subnet IDs (from vpc module)
cluster_security_group_id # Cluster security group ID (from security module)
```

### Optional Variables

```hcl
kubernetes_version          = string   # K8s version (default: 1.28)
endpoint_private_access     = bool     # Private API endpoint (default: true)
endpoint_public_access      = bool     # Public API endpoint (default: true)
public_access_cidrs         = list     # Public access CIDR blocks
enabled_cluster_log_types   = list     # Log types (default: [api, audit])
log_retention_days          = number   # CloudWatch retention (default: 7)
base_tags                   = map      # Tags for resources
```

### Outputs

```hcl
cluster_id                          # Cluster ID
cluster_name                        # Cluster name
cluster_arn                         # Cluster ARN
cluster_version                     # Kubernetes version
cluster_endpoint                    # API endpoint URL
cluster_certificate_authority_data  # CA certificate (base64)
cluster_oidc_issuer_url            # OIDC provider URL
cluster_platform_version           # EKS platform version
cluster_status                     # Cluster status
```

### Kubernetes Versions

Supported versions depend on AWS region. Common versions:
- 1.28 (stable)
- 1.27
- 1.26
- 1.25

### Log Types

```hcl
enabled_cluster_log_types = [
  "api",              # API calls
  "audit",            # Audit logs
  "authenticator",    # Authentication
  "controllerManager", # Controller actions
  "scheduler"         # Scheduler events
]
```

### Usage Example

```hcl
module "eks_cluster" {
  source = "./modules/eks"
  
  cluster_name               = "myapp-dev-eks"
  cluster_name_prefix        = "myapp-dev"
  kubernetes_version         = "1.28"
  cluster_iam_role_arn       = module.iam.cluster_iam_role_arn
  private_subnet_ids         = module.vpc.private_subnet_ids
  public_subnet_ids          = module.vpc.public_subnet_ids
  cluster_security_group_id  = module.security.cluster_security_group_id
  
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs    = ["0.0.0.0/0"]
  
  enabled_cluster_log_types = ["api", "audit"]
  log_retention_days       = 7
}
```

---

## Node Group Module

**Location**: `modules/node_group/`

**Purpose**: Create and manage EKS worker node groups

### Resources Created
- Managed node group for EKS cluster
- Auto-scaling configuration
- Node labels and taints
- CloudWatch auto-scaling hooks

### Required Variables

```hcl
cluster_name            # EKS cluster name
cluster_name_prefix     # Naming prefix
node_group_iam_role_arn # Node IAM role ARN (from iam module)
private_subnet_ids      # Private subnet IDs (from vpc module)
```

### Optional Variables

```hcl
kubernetes_version          = string   # K8s version (default: 1.28)
desired_size                = number   # Desired nodes (default: 2)
min_size                    = number   # Minimum nodes (default: 1)
max_size                    = number   # Maximum nodes (default: 4)
max_unavailable_percentage  = number   # Update max unavailable % (default: 33)
capacity_type               = string   # ON_DEMAND or SPOT (default: ON_DEMAND)
instance_types              = list     # EC2 types (default: [t3.medium])
disk_size                   = number   # Root volume size GB (default: 20)
enable_remote_access        = bool     # SSH access (default: false)
ec2_ssh_key_name            = string   # SSH key name
source_security_group_ids   = list     # SGs for remote access
labels                      = map      # Kubernetes labels
taints                      = list     # Kubernetes taints
base_tags                   = map      # Tags for resources
```

### Scaling Configuration

```hcl
# Min-Max auto-scaling
desired_size = 2
min_size     = 1
max_size     = 4

# Terraform ignores manual scaling changes (ignores changes)
# Use HPA for application-level auto-scaling
```

### Instance Types

**General Purpose:**
```hcl
instance_types = ["t3.medium"]   # Dev/test
instance_types = ["t3.large"]    # Small production
instance_types = ["m5.large"]    # Standard
instance_types = ["m5.xlarge"]   # Large workloads
```

**Burstable:**
```hcl
instance_types = ["t3.micro"]    # Testing only
instance_types = ["t3.small"]    # Light workloads
```

**Memory-Optimized:**
```hcl
instance_types = ["r5.large"]    # High memory needs
```

**GPU:**
```hcl
instance_types = ["g4dn.xlarge"] # GPU workloads
```

### Labels and Taints

```hcl
# Labels: Soft constraints, pods attracted to labeled nodes
labels = {
  workload_type = "general"
  environment   = "dev"
}

# Taints: Hard constraints, pods must tolerate taint
taints = [
  {
    key    = "workload"
    value  = "gpu"
    effect = "NoSchedule"  # or NoExecute, PreferNoSchedule
  }
]
```

### Usage Example

```hcl
module "node_group" {
  source = "./modules/node_group"
  
  cluster_name           = module.eks_cluster.cluster_name
  cluster_name_prefix    = "myapp-dev"
  node_group_iam_role_arn = module.iam.node_group_iam_role_arn
  private_subnet_ids     = module.vpc.private_subnet_ids
  
  # Scaling
  desired_size = 2
  min_size     = 1
  max_size     = 4
  
  # Compute
  instance_types = ["t3.medium"]
  capacity_type  = "ON_DEMAND"
  disk_size      = 30
  
  # Kubernetes
  labels = {
    workload = "general"
  }
  
  taints = []
  
  base_tags = {
    Environment = "dev"
  }
}
```

---

## Module Dependencies

```
VPC → Security, IAM
        ↓
     EKS Cluster
        ↓
   Node Group
```

## Common Module Patterns

### Pattern 1: Multiple Node Groups

Extend `main.tf`:

```hcl
module "node_group_general" {
  source = "./modules/node_group"
  # ... general workload config
}

module "node_group_gpu" {
  source = "./modules/node_group"
  instance_types = ["g4dn.xlarge"]
  taints = [{
    key    = "gpu"
    value  = "true"
    effect = "NoSchedule"
  }]
  # ... GPU-specific config
}

module "node_group_spot" {
  source = "./modules/node_group"
  capacity_type = "SPOT"
  # ... spot instance config
}
```

### Pattern 2: Multiple Environments

Different `root` modules per environment:

```
projects/
├── dev/
│   ├── main.tf (calls modules)
│   └── terraform.tfvars (dev config)
├── staging/
│   ├── main.tf
│   └── terraform.tfvars
└── modules/ (shared)
```

Each environment uses same modules, different variables.

---

For detailed configuration options, refer to individual module `variables.tf` files.
