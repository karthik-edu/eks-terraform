# Modular Terraform Architecture Guide

## Overview

This EKS project demonstrates a production-grade modular Terraform architecture with clean separation of concerns, reusability, and best practices.

## Architectural Principles

### 1. **Module-Based Structure**

Each module encapsulates a specific AWS service/concern:

```
modules/
├── vpc/           → VPC, subnets, gateways, routing
├── security/      → Security groups and rules
├── iam/           → IAM roles, policies, OIDC provider
├── eks/           → EKS cluster configuration
└── node_group/    → Worker node groups
```

**Benefits:**
- ✅ Single Responsibility Principle (SRP)
- ✅ Reusable across projects
- ✅ Easy to test and validate
- ✅ Clear ownership and dependencies
- ✅ Reduced complexity per file

### 2. **Clean Input Variables**

Root module `variables.tf` provides:
- **Clear, descriptive names**: `node_desired_size` not `ds`
- **Input validation**: Catches errors before deployment
- **Sensible defaults**: Works out-of-box
- **Grouped variables**: Organized by concern

```hcl
# Bad: Unclear purpose
variable "vr" { type = string }

# Good: Clear, validated, with description
variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr_block, 0))
    error_message = "Must be valid CIDR notation."
  }
}
```

### 3. **Module Composition**

Root module orchestrates sub-modules:

```hcl
# main.tf - Clean composition
module "vpc" {
  source = "./modules/vpc"
  # Pass only needed variables
}

module "eks_cluster" {
  source = "./modules/eks"
  # Dependencies on other modules
  depends_on = [module.iam]
}
```

**Why this matters:**
- Data flows explicitly through variables/outputs
- Easy to understand dependencies
- Changes in one module don't affect others

### 4. **Consistent Module Interface**

Each module follows the pattern:

```
module_name/
├── main.tf       # Resources
├── variables.tf  # Inputs (3-5 per module)
└── outputs.tf    # Exports needed by consumers
```

**Module Contract:**
- `variables.tf`: What this module needs
- `main.tf`: What this module creates
- `outputs.tf`: What others can use

### 5. **Distinction: Root vs. Module**

**Root Module (`./`):**
- Entry point for Terraform
- Calls other modules
- Handles provider configuration
- Contains main orchestration logic

**Sub-Modules (`./modules/*/`):**
- Self-contained, reusable components
- No provider blocks (inherited from root)
- Pass minimal, focused inputs
- Export outputs for composition

## Module Deep Dives

### VPC Module

**Responsibility**: Network infrastructure

```hcl
# Input: Network design parameters
input: vpc_cidr_block, subnet_counts, availability_zones

# Output: Network IDs
output: vpc_id, subnet_ids, route_table_ids

# Design Pattern:
# - Takes CIDR block, creates subnets dynamically
# - Calculates IPs using cidrsubnet()
# - Adds Kubernetes-specific tags for ELB discovery
```

**Reusability:**
- Used for any EKS, ECS, or general AWS VPC
- Adjustable subnet counts
- Dynamic AZ selection

### IAM Module

**Responsibility**: Access control and permissions

```hcl
# Input: Service requirements
input: cluster_name, oidc_issuer_url

# Output: Authorized entities
output: cluster_role_arn, node_role_arn, oidc_provider_arn

# Design Pattern:
# - Creates roles with specific trust relationships
# - Attaches only necessary policies (principle of least privilege)
# - Sets up OIDC for IRSA (Kubernetes service account IAM)
```

**Security Benefits:**
- Minimal permissions (not all EC2/IAM access)
- Separate cluster vs. node roles
- OIDC for fine-grained workload permissions

### Security Module

**Responsibility**: Network security rules

```hcl
# Input: VPC context, access requirements
input: vpc_id, enable_ssh_access

# Output: Security group IDs
output: cluster_sg_id, node_sg_id

# Design Pattern:
# - Separate security groups for cluster and nodes
# - Rules enforcing node-to-cluster communication
# - Optional SSH (disabled by default)
```

**Best Practices:**
- Ingress rules: Only what's needed
- Egress rules: Unrestricted for flexibility
- Security group references instead of CIDRs

### EKS Module

**Responsibility**: Kubernetes control plane

```hcl
# Input: Cluster requirements
input: cluster_name, kubernetes_version, enabled_logs

# Output: Cluster credentials
output: cluster_endpoint, ca_data, oidc_url

# Design Pattern:
# - Configurable features (private/public endpoints)
# - Logging configuration
# - Return credentials for kubeconfig
```

**Extensibility:**
- Easy to add add-ons (VPN, monitoring, etc.)
- Supports multiple minor versions
- CloudWatch integration

### Node Group Module

**Responsibility**: Worker node infrastructure

```hcl
# Input: Compute specifications
input: instance_types, scaling_config, labels

# Output: Node group status
output: node_group_id, status, resources

# Design Pattern:
# - Flexible compute options (ON_DEMAND/SPOT)
# - Dynamic labels and taints
# - Auto-scaling configuration
```

**Production Features:**
- Rolling update strategy
- Multi-instance type support
- Kubernetes workload scheduling controls

## Data Flow Architecture

```
terraform.tfvars (User Input)
         ↓
variables.tf (Validation)
         ↓
main.tf (Module Orchestration)
         ↓
modules/* (Resource Creation)
         ↓
outputs.tf (Exported Values)
```

## Variable Flow Through Modules

```hcl
# Root module receives user input
variable "cluster_name" { ... }

# Passes to sub-modules with locals for computation
module "eks_cluster" {
  cluster_name = "${local.name_prefix}-${var.cluster_name}"
}

# Sub-module uses and exports values
# modules/eks/variables.tf { cluster_name = "value" }
# modules/eks/outputs.tf { cluster_arn = aws_eks_cluster.main.arn }

# Root module re-exports for user
output "cluster_arn" {
  value = module.eks_cluster.cluster_arn
}
```

## Best Practices Implemented

### 1. **DRY Principle (Don't Repeat Yourself)**
- Common tags in `locals.tf`
- Naming convention in one place
- Shared validation patterns

### 2. **Explicit Dependencies**
```hcl
# Good: Clear dependency
depends_on = [module.iam]

# Bad: Implicit dependency through interpolation
depends_on = [var.user_provided_arn]
```

### 3. **Variable Validation**
```hcl
# Every variable has validation OR clear description
variable "instance_types" {
  validation {
    condition     = alltrue([for it in var.instance_types : can(regex("^[a-z]{1,2}\\d.*\\w$", it))])
    error_message = "Instance types must be valid AWS types."
  }
}
```

### 4. **Consistent Naming Convention**
```
${project}-${environment}-${resource_type}

Examples:
- myapp-dev-vpc
- myapp-dev-node-sg
- myapp-dev-eks-cluster
- myapp-dev-node-group
```

### 5. **Minimal Module Inputs**
```hcl
# Good: 5-7 focused inputs
module "vpc" {
  vpc_cidr_block  = var.vpc_cidr_block
  subnet_counts   = var.private_subnet_count
  availability_zones = local.availability_zones
}

# Bad: 40 inputs, tight coupling
module "vpc" {
  everything_needed = var.everything  # Hard to use
}
```

### 6. **Outputs for Consumption**
```hcl
# Modules export what others need
output "vpc_id" { value = aws_vpc.main.id }
output "private_subnet_ids" { value = aws_subnet.private[*].id }

# Root module re-exports key values
output "cluster_endpoint" { value = module.eks_cluster.endpoint }
```

### 7. **Sensitive Values**
```hcl
# Mark credentials
output "certificate_authority_data" {
  value     = module.eks_cluster.ca_data
  sensitive = true  # Won't appear in logs
}

variable "aws_profile" {
  sensitive = true  # Hides from state
}
```

## Testing Modules

### Module Unit Tests
```bash
# Test module in isolation
cd modules/vpc

terraform init
terraform validate
terraform plan -var-file=test.tfvars
```

### Integration Tests
```bash
# Test root module with all modules
terraform init
terraform validate
terraform plan
terraform apply -auto-approve

# Verify in AWS
aws eks describe-cluster --name myapp-dev-eks
```

### Syntax Check
```bash
terraform fmt -recursive -check
terraform validate
tfsec .
```

## Extending the Architecture

### Adding a New Module

1. **Create module directory**
   ```bash
   mkdir modules/monitoring
   ```

2. **Define module interface**
   ```hcl
   # modules/monitoring/variables.tf
   variable "cluster_name" { ... }
   
   # modules/monitoring/outputs.tf
   output "cloudwatch_log_group" { ... }
   ```

3. **Implement resources**
   ```hcl
   # modules/monitoring/main.tf
   resource "aws_cloudwatch_log_group" "eks" { ... }
   ```

4. **Compose in root**
   ```hcl
   # main.tf
   module "monitoring" {
     source = "./modules/monitoring"
     cluster_name = module.eks_cluster.cluster_name
   }
   ```

### Making Modules Optional

```hcl
variable "enable_monitoring" {
  description = "Enable monitoring module"
  type        = bool
  default     = false
}

module "monitoring" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/monitoring"
  ...
}

output "monitoring_dashboard" {
  value = try(module.monitoring[0].dashboard_url, null)
}
```

## Scaling to Multiple Clusters

Reuse modules for multiple clusters:

```bash
# Directory structure
├── dev-cluster/
│   ├── terraform.tfvars
│   ├── main.tf (links to modules)
│   └── variables.tf
├── staging-cluster/
│   ├── terraform.tfvars
│   ├── main.tf
│   └── variables.tf
├── prod-cluster/
│   └── ...
└── modules/
    ├── vpc/
    ├── security/
    ├── iam/
    ├── eks/
    └── node_group/
```

Each cluster workspace uses same modules with different inputs!

## Version Management

### Module Versioning (in Git tags)
```bash
# Tag module version
git tag modules/vpc/v1.0.0

# Reference in other projects
source = "git::https://github.com/myorg/terraform-modules.git//vpc?ref=v1.0.0"
```

### Provider Versioning
```hcl
# terraform.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Allows 5.x but not 6.0+
    }
  }
}
```

## Common Mistakes to Avoid

❌ **Mistake 1: Too Many Module Inputs**
```hcl
# Bad: Module has no clear boundaries
module "everything" {
  cluster_name = "x"
  vpc_cidr = "y"
  # ... 50 more variables
}
```

✅ **Solution**: Keep modules focused (5-10 inputs max)

---

❌ **Mistake 2: Hardcoded Values**
```hcl
# Bad: Can't reuse across projects
resource "aws_eks_cluster" "main" {
  name = "my-cluster"  # Specific name
}
```

✅ **Solution**: Use variables and locals
```hcl
name = "${local.name_prefix}-${var.cluster_name}"
```

---

❌ **Mistake 3: Circular Dependencies**
```hcl
# Bad: Module A needs Module B's output, but B needs A's
module "a" {
  input = module.b.output
}

module "b" {
  input = module.a.output
}
```

✅ **Solution**: Design dependency graph carefully (DAG)

---

❌ **Mistake 4: Provider Blocks in Modules**
```hcl
# Bad (in modules/eks/main.tf)
provider "aws" { region = var.region }
```

✅ **Solution**: Only in root module

---

❌ **Mistake 5: No Input Validation**
```hcl
# Bad: Any string accepted
variable "cluster_name" { type = string }
```

✅ **Solution**: Add validation
```hcl
variable "cluster_name" {
  type = string
  validation {
    condition = can(regex("^[a-z0-9-]{1,37}$", var.cluster_name))
    error_message = "Invalid cluster name format"
  }
}
```

## Summary

This architecture provides:

✅ **Modularity**: Independent, testable components  
✅ **Scalability**: Reuse across multiple clusters/projects  
✅ **Clarity**: Clear data flow and dependencies  
✅ **Maintainability**: Simple to understand and modify  
✅ **Security**: Principle of least privilege  
✅ **Extensibility**: Easy to add new features  
✅ **Best Practices**: Follows Terraform and AWS guidelines  

Use this as a template for production Terraform projects!
