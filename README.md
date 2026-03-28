# EKS Modular Terraform Project - Quick Start & Configuration Guide

## Overview

This is a production-ready, modularized Terraform project for deploying AWS EKS (Elastic Kubernetes Service) clusters with best practices and clean input variables.

### Directory Structure

```
eks-modular/
├── terraform.tf                 # Terraform version and backend config
├── provider.tf                  # Provider configuration
├── variables.tf                 # Input variables
├── locals.tf                    # Local values
├── data.tf                      # Data sources
├── main.tf                      # Module instantiation
├── outputs.tf                   # Output values
├── terraform.tfvars             # Variable values (customize this)
├── .gitignore                   # Git ignore rules
├── README.md                    # This file
└── modules/
    ├── vpc/                     # VPC and networking
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── security/                # Security groups
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── iam/                     # IAM roles and policies
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── eks/                     # EKS cluster
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── node_group/              # EKS node groups
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## What Gets Created

### 1. **VPC & Networking**
   - VPC with private and public subnets across multiple AZs
   - Internet Gateway for public internet access
   - NAT Gateway for private subnet outbound traffic
   - Route tables for public and private subnets
   - Proper tagging for EKS subnet discovery

### 2. **IAM Roles & Policies**
   - **Cluster IAM Role**: For EKS control plane to manage AWS resources
   - **Node IAM Role**: For worker nodes to access ECR, EBS, CloudWatch, etc.
   - **OIDC Provider**: For IRSA (IAM Roles for Service Accounts)
   - All required AWS managed policies attached

### 3. **Security Groups**
   - Cluster security group with proper ingress/egress rules
   - Node security group with pod-to-pod communication
   - Node-to-cluster communication rules
   - Optional SSH access configuration

### 4. **EKS Cluster**
   - Managed Kubernetes control plane
   - Configurable Kubernetes version
   - Private and public API endpoints
   - CloudWatch logging enabled
   - Automatic node security group attachment

### 5. **Node Group**
   - Auto-scaling managed node group
   - Configurable instance types and capacity
   - ON_DEMAND or SPOT capacity pricing
   - Kubernetes labels and taints support
   - Optional remote access via SSH

## Prerequisites

1. **AWS Account** with appropriate IAM permissions
2. **Terraform** >= 1.0
   ```bash
   terraform version
   ```
3. **AWS CLI** configured with credentials
   ```bash
   aws configure --profile your-profile
   ```
4. **kubectl** for Kubernetes management (optional but recommended)
   ```bash
   kubectl version --client
   ```

## Quick Start

### 1. Clone/Setup Repository
```bash
cd eks-modular
```

### 2. Customize Variables
Edit `terraform.tfvars` with your values:

```hcl
project_name     = "your-project"
environment      = "dev"           # or staging, prod
aws_region       = "us-east-1"
aws_profile      = "your-profile"
kubernetes_version = "1.28"
```

### 3. Initialize Terraform
```bash
terraform init
```

### 4. Validate Configuration
```bash
terraform validate
terraform fmt -recursive
```

### 5. Plan Deployment
```bash
terraform plan -out=tfplan
```

### 6. Apply Configuration
```bash
terraform apply tfplan
```

### 7. Configure kubectl
```bash
# Get the command from outputs
aws eks update-kubeconfig \
  --region us-east-1 \
  --name your-project-dev-eks

# Verify cluster access
kubectl get nodes
```

## Configuration Options

### Project Configuration
```hcl
project_name  = "myapp"           # Prefix for all resources
environment   = "dev"             # dev, staging, prod
aws_region    = "us-east-1"       # AWS region
aws_profile   = "default"         # AWS CLI profile

common_tags = {
  ManagedBy   = "Terraform"
  Owner       = "DevOps"
  CostCenter  = "Engineering"
}
```

### VPC Configuration
```hcl
vpc_cidr_block           = "10.0.0.0/16"
availability_zone_count  = 2                # Multi-AZ deployment
private_subnet_count     = 2
public_subnet_count      = 2
```

### EKS Cluster Configuration
```hcl
cluster_name            = "eks"
kubernetes_version      = "1.28"           # Latest stable: 1.28
endpoint_private_access = true             # Private API endpoint
endpoint_public_access  = true             # Public API endpoint
public_access_cidrs     = ["0.0.0.0/0"]    # Restrict in production!
enabled_cluster_log_types = [              # CloudWatch logs
  "api",
  "audit",
  "authenticator",
  "controllerManager",
  "scheduler"
]
log_retention_days      = 7                # CloudWatch retention
```

### Node Group Configuration
```hcl
# Scaling
node_desired_size = 2
node_min_size     = 1
node_max_size     = 4

# Compute
node_instance_types = ["t3.medium"]        # Can be list for diverse fleet
node_capacity_type  = "ON_DEMAND"          # ON_DEMAND or SPOT
node_disk_size      = 30                   # Root volume size in GB

# Kubernetes
node_labels = {
  Environment = "dev"
  Team        = "platform"
}

# Optional: Taints
node_taints = [
  {
    key    = "dedicated"
    value  = "worker"
    effect = "NoSchedule"
  }
]
```

### Security Configuration
```hcl
# Remote SSH Access (if needed)
enable_node_remote_access = false
node_ssh_key_name         = "my-key"       # EC2 key pair name
enable_node_ssh           = false
node_ssh_cidr             = "10.0.0.0/8"   # Your corporate CIDR

# API Endpoint Access (restrict in production!)
endpoint_public_access = true
public_access_cidrs    = ["YOUR_IP/32"]    # Instead of 0.0.0.0/0
```

## Outputs

After deployment, access outputs with:

```bash
# All outputs
terraform output

# Specific output
terraform output cluster_endpoint
terraform output -json > outputs.json

# Configure kubectl (from output)
$(terraform output -raw configure_kubectl)
```

**Important Outputs:**
- `cluster_name`: EKS cluster name
- `cluster_endpoint`: Kubernetes API endpoint
- `cluster_certificate_authority_data`: CA certificate for kubectl
- `cluster_oidc_issuer_url`: For IRSA configuration
- `node_group_id`: Node group identifier

## Usage Examples

### Example 1: Development Cluster
```hcl
# terraform.tfvars
project_name         = "demo-app"
environment          = "dev"
kubernetes_version   = "1.28"
node_desired_size    = 1
node_instance_types  = ["t3.small"]
node_capacity_type   = "SPOT"              # Cost savings
endpoint_public_access = true
```

### Example 2: Production Cluster
```hcl
# terraform.tfvars
project_name         = "demo-app"
environment          = "prod"
kubernetes_version   = "1.28"
availability_zone_count = 3                # Maximum HA
node_desired_size    = 3
node_min_size        = 3
node_max_size        = 10
node_instance_types  = ["t3.large", "t3a.large"]
node_capacity_type   = "ON_DEMAND"
endpoint_public_access = false              # Private only
public_access_cidrs  = ["10.0.0.0/8"]
enable_node_remote_access = true
enable_node_ssh      = true
node_ssh_cidr        = "10.0.0.0/8"
```

### Example 3: Multiple Node Groups
To create multiple node groups, repeat the node_group module in `main.tf`:

```hcl
# Add to main.tf
module "node_group_cpu" {
  source = "./modules/node_group"
  # ... same config as above
}

module "node_group_gpu" {
  source = "./modules/node_group"
  
  instance_types = ["g4dn.xlarge"]
  
  labels = {
    workload_type = "gpu"
  }
  
  taints = [
    {
      key    = "gpu"
      value  = "true"
      effect = "NoSchedule"
    }
  ]
}
```

## Deployment Workflow

### Initial Setup
```bash
# 1. Edit tfvars
nano terraform.tfvars

# 2. Initialize
terraform init

# 3. Validate
terraform validate && terraform fmt -recursive

# 4. Plan
terraform plan -out=tfplan

# 5. Review and apply
terraform apply tfplan

# 6. Get kubeconfig
aws eks update-kubeconfig --region us-east-1 --name my-cluster
```

### Day 2 Operations

**Scale Nodes**
```bash
# Edit tfvars
project_name = "demo"
node_desired_size = 5    # Change this

# Apply
terraform plan -out=tfplan
terraform apply tfplan
```

**Update Kubernetes Version**
```bash
# First update cluster
kubernetes_version = "1.29"
terraform apply

# Then update node group
# Terraform handles rolling updates automatically
```

**Add Node Labels**
```hcl
node_labels = {
  Environment = "prod"
  Team        = "platform"
  Workload    = "general"
}
```

**Enable Logging**
```hcl
enabled_cluster_log_types = [
  "api",
  "audit",
  "authenticator",
  "controllerManager",
  "scheduler"
]
```

## Troubleshooting

### Module Not Found
```bash
terraform init -upgrade
rm -rf .terraform .terraform.lock.hcl
terraform init
```

### OIDC Certificate Error
The OIDC provider depends on cluster creation. If it fails:
```bash
terraform apply -target=module.eks_cluster
terraform apply  # Complete apply
```

### Node Group Not Joining Cluster
1. Check security groups allow communication
2. Verify IAM role has proper policies
3. Check CNI plugin compatibility

```bash
kubectl get nodes
kubectl describe node <node-name>
```

### Cluster API Not Accessible
```bash
# Check endpoint settings
terraform output cluster_endpoint

# Verify security group rules
aws ec2 describe-security-groups --group-ids <sg-id>

# Test connectivity
curl https://<endpoint>/api/v1
```

## Best Practices Implemented

✅ **Modularity**: Separate modules for each concern  
✅ **Input Validation**: All variables have validation rules  
✅ **Clean Inputs**: Meaningful defaults and required variables  
✅ **Security**: Least privilege IAM roles, proper security groups  
✅ **High Availability**: Multi-AZ deployment by default  
✅ **Logging**: CloudWatch logging enabled  
✅ **Tagging**: Comprehensive tagging strategy  
✅ **IRSA**: OIDC provider for Kubernetes service account IAM  
✅ **Scalability**: Dynamic node group configuration  
✅ **Cost Control**: SPOT instance support, right-sized defaults  

## Security Considerations

### Production Checklist
- [ ] Restrict `public_access_cidrs` to known IPs
- [ ] Enable `endpoint_private_access` for cluster-internal traffic
- [ ] Use `ON_DEMAND` capacity for stable workloads
- [ ] Enable all `enabled_cluster_log_types` for audit logging
- [ ] Configure pod security policies/standards
- [ ] Use Network Policies for pod-to-pod security
- [ ] Enable EBS encryption for node volumes
- [ ] Restrict SSH access with `enable_node_ssh = false`
- [ ] Use private subnets for nodes
- [ ] Implement RBAC policies

### Development/Testing
- May use public API access
- SPOT instances for cost savings
- Smaller node groups
- SSH access for debugging

## Maintenance

### Kubernetes Version Upgrades
```bash
# Update in tfvars
kubernetes_version = "1.29"

# Plan and apply (rolling update)
terraform plan
terraform apply

# Verify nodes
kubectl get nodes
```

### Auto-scaling
Terraform manages desired size. For automatic scaling based on load:

```bash
# Install metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Deploy HPA
kubectl autoscale deployment my-app --min=2 --max=10 --cpu-percent=80
```

## Cleanup

### Destroy All Resources
```bash
# Review what will be destroyed
terraform plan -destroy

# Destroy
terraform destroy

# Verify in AWS console
```

## Additional Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [HashiCorp Terraform Modules](https://registry.terraform.io/search/modules?namespace=terraform-aws-modules)

## License

This project is provided as-is.

## Support

For issues:
1. Check AWS documentation
2. Review Terraform provider documentation
3. Check CloudWatch logs
4. Verify security group rules
5. Test kubectl connectivity

---

**Author**: DevOps Team  
**Last Updated**: March 2026  
**Terraform Version**: >= 1.0  
**AWS Provider Version**: ~> 5.0
