# Get a list of Availability Zones in the current region
data "aws_availability_zones" "available" {
  state = "available"
}

# --- VPC ---
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-${var.stack}-${var.module_name}-vpc"
    Project     = var.project_name
    Environment = var.stack
  }
}

# --- Subnets ---
resource "aws_subnet" "public" {
  count                   = 2 # Create 2 public subnets in different AZs
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.stack}-${var.module_name}-public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count             = 2 # Create 2 private subnets in different AZs
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-${var.stack}-${var.module_name}-private-subnet-${count.index + 1}"
  }
}

# --- Internet Gateway for Public Subnets ---
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-${var.stack}-${var.module_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.stack}-${var.module_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Note: A production setup would include NAT Gateways for private subnets to access the internet.
# This has been omitted to simplify the setup and avoid costs not covered by the Free Tier.
# Lambda functions in private subnets will need VPC Endpoints to access AWS services.