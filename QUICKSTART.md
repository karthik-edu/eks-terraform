# Quick Start Commands

## Initial Setup
```bash
# 1. Edit configuration
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

# 2. Initialize
terraform init

# 3. Validate and format
terraform validate
terraform fmt -recursive

# 4. Dry run
terraform plan -out=tfplan

# 5. Deploy
terraform apply tfplan
```

## Post-Deployment
```bash
# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name {project}-{env}-eks

# Verify cluster access
kubectl cluster-info
kubectl get nodes

# Get cluster info
terraform output cluster_endpoint
terraform output cluster_certificate_authority_data
```

## Common Operations

### View Current State
```bash
terraform state list
terraform state show module.eks_cluster.aws_eks_cluster.main
terraform output -json
```

### Modify Cluster
```bash
# Update tfvars
nano terraform.tfvars

# Plan changes
terraform plan

# Apply
terraform apply
```

### Update Node Count
```bash
# Edit tfvars
node_desired_size = 5

# Apply (rolling update)
terraform apply
```

### Add Node Variables
```hcl
# In terraform.tfvars
node_labels = {
  workload_type = "general"
  team = "platform"
}
```

### Upgrade Kubernetes
```hcl
# In terraform.tfvars
kubernetes_version = "1.29"

# Check plan
terraform plan

# Apply (EKS manages rolling updates)
terraform apply

# Wait for nodes to update
watch kubectl get nodes
```

## Debugging

### Check Module Dependencies
```bash
terraform graph | grep -E "(module|aws_)"
```

### Check Resource Creation Order
```bash
terraform plan | grep "must be replaced"
```

### Show Current Configuration
```bash
terraform show
terraform show -json | jq '.values.root_module.child_modules'
```

### Check State Consistency
```bash
terraform refresh
terraform plan  # Should show no changes
```

### Validate Module Independently
```bash
cd modules/vpc
terraform init
terraform plan
cd ../..
```

## Security Operations

### Rotate Credentials
```bash
aws ec2 create-key-pair --key-name new-key --query 'KeyMaterial' > new-key.pem
# Update terraform.tfvars: node_ssh_key_name = "new-key"
terraform apply
```

### Check Security Group Rules
```bash
terraform state show module.security.aws_security_group.cluster
aws ec2 describe-security-groups --query 'SecurityGroups[*].[GroupId,GroupName]'
```

### Audit IAM Permissions
```bash
terraform output cluster_iam_role_arn
terraform output node_group_iam_role_arn
```

## Cost Optimization

### Use SPOT Instances
```hcl
# terraform.tfvars
node_capacity_type = "SPOT"  # 70-90% cost savings
```

### Right-size Instances
```hcl
node_instance_types = ["t3.small"]  # Smaller for dev
# vs.
node_instance_types = ["t3.xlarge", "t3a.xlarge"]  # Larger for prod
```

### Cleanup
```bash
# List all resources
terraform state list

# Destroy everything
terraform destroy

# Or destroy specific module
terraform destroy -target=module.node_group
```

## Troubleshooting

### Module Error: Provider Config Missing
```bash
# Reinitialize
rm -rf .terraform .terraform.lock.hcl
terraform init
```

### OIDC Certificate Error
```bash
# First deploy cluster
terraform apply -target=module.eks_cluster

# Then complete deployment
terraform apply
```

### Node Not Joining Cluster
```bash
# Check node security group
aws ec2 describe-security-groups --group-ids sg-xxx

# Check IAM role
aws iam get-role --role-name {project}-{env}-node

# Check logs
kubectl logs -n kube-system -l k8s-app=aws-node
```

### Cannot Access Cluster API
```bash
# Check endpoint
terraform output cluster_endpoint

# Verify security group ingress
aws ec2 describe-security-group-rules --filters "Name=group-id,Values=sg-xxx"

# Test connectivity
curl -k https://{endpoint}/api/v1 -H "Authorization: Bearer {token}"
```

## Useful Queries

### List All EKS Clusters in Region
```bash
aws eks list-clusters
aws eks describe-cluster --name {name}
```

### Check Node Group Status
```bash
aws eks describe-nodegroup --cluster-name {name} --nodegroup-name {nodegroup}
```

### View Terraform State Size
```bash
wc -l terraform.tfstate
du -sh terraform.tfstate
```

### Export Configuration
```bash
terraform output -json > config-backup.json
```

## Documentation References

- **README.md**: Main documentation and usage guide
- **ARCHITECTURE.md**: Modular architecture explanation
- **Module_README.md**: Individual module documentation
- **terraform.tfvars**: Configuration examples

---

For detailed information, refer to main README.md or module-specific documentation.
