################################################################################
# VPC
################################################################################
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.base_tags,
    {
      Name = "${var.name_prefix}-vpc"
    }
  )
}

################################################################################
# Internet Gateway
################################################################################
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.base_tags,
    {
      Name = "${var.name_prefix}-igw"
    }
  )

  depends_on = [aws_vpc.main]
}

################################################################################
# Private Subnets
################################################################################
resource "aws_subnet" "private" {
  count             = var.private_subnet_count
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index)

  map_public_ip_on_launch = false

  tags = merge(
    var.base_tags,
    {
      Name                            = "${var.name_prefix}-private-subnet-${count.index + 1}"
      Type                            = "Private"
      "kubernetes.io/role/internal-elb" = "1"
    }
  )

  depends_on = [aws_vpc.main]
}

################################################################################
# Public Subnets
################################################################################
resource "aws_subnet" "public" {
  count             = var.public_subnet_count
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index + var.private_subnet_count)

  map_public_ip_on_launch = true

  tags = merge(
    var.base_tags,
    {
      Name                   = "${var.name_prefix}-public-subnet-${count.index + 1}"
      Type                   = "Public"
      "kubernetes.io/role/elb" = "1"
    }
  )

  depends_on = [aws_vpc.main]
}

################################################################################
# Elastic IP for NAT Gateway
################################################################################
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(
    var.base_tags,
    {
      Name = "${var.name_prefix}-nat-eip"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

################################################################################
# NAT Gateway
################################################################################
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    var.base_tags,
    {
      Name = "${var.name_prefix}-nat-gateway"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

################################################################################
# Public Route Table
################################################################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.main.id
  }

  tags = merge(
    var.base_tags,
    {
      Name = "${var.name_prefix}-public-rt"
    }
  )
}

################################################################################
# Public Route Table Associations
################################################################################
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[count.index].id
}

################################################################################
# Private Route Table
################################################################################
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(
    var.base_tags,
    {
      Name = "${var.name_prefix}-private-rt"
    }
  )
}

################################################################################
# Private Route Table Associations
################################################################################
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private[count.index].id
}
