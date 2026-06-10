resource aws_vpc "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Public Subnets (Load Balancer live here)

resource aws_subnet "public" {
    count = length(var.public_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidrs[count.index]
    availability_zone = var.availability_zones[count.index]

    map_public_ip_on_launch = true
}

# private subnets (EKS + RDS live here)

resource aws_subnet "private" {
    count = length(var.public_subnet_cidrs)
    cidr_block = var.private_subnet_cidrs[count.index]
    vpc_id = aws_vpc.main.id
    availability_zone = var.availability_zones[count.index]
}

# Internet Gateway (for public subnet to access internet)

resource aws_internet_gateway "igw" {
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "${var.project_name}-igw"
    }
}

# Elastic IP for NAT Gateway (for private subnet to access internet)

resource aws_eip "nat" {
    domain = "vpc"
    tags = {
        Name = "${var.project_name}-nat-eip"
    }
}

# NAT Gateway (for private subnet to access internet)
resource aws_nat_gateway "nat" {
    allocation_id = aws_eip.nat.id
    subnet_id = aws_subnet.public[0].id
    tags = {
        Name = "${var.project_name}-nat-gateway"
    }
}

# Route Table for public subnets (to route traffic to Internet Gateway)

resource aws_route_table "public" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id= aws_internet_gateway.igw.id
    }
}

# Route Table for private subnets (to route traffic to NAT Gateway)

resource aws_route_table "private" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id= aws_nat_gateway.nat.id
    }
}

# Associate public subnets with public route table
resource aws_route_table_association "public" {
    count = length(var.public_subnet_cidrs)
    subnet_id = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id
}

# Associate private subnets with private route table
resource aws_route_table_association "private" {
    count = length(var.private_subnet_cidrs)
    subnet_id = aws_subnet.private[count.index].id
    route_table_id = aws_route_table.private.id
}

