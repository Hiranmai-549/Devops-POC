provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = { Name = "main-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "main-igw" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-rt" }
}

resource "aws_subnet" "public" {
  count = 3
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${var.aws_region}${element(var.availability_zones, count.index)}"
  tags = { Name = "public-subnet-${count.index}" }
}

resource "aws_route_table_association" "public_assoc" {
  count = 3
  subnet_id = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_subnet" "private" {
  count = 3
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.${count.index + 3}.0/24"
  availability_zone = "${var.aws_region}${element(var.availability_zones, count.index)}"
  tags = { Name = "private-subnet-${count.index}" }
}

resource "aws_eip" "nat" {
  count = 3
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gw" {
  count = 3
  allocation_id = element(aws_eip.nat[*].id, count.index)
  subnet_id = element(aws_subnet.public[*].id, count.index)
  tags = { Name = "nat-gw-${count.index}" }
}

resource "aws_route_table" "private_rt" {
  count = 3
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat_gw[*].id, count.index)
  }
  tags = { Name = "private-rt-${count.index}" }
}

resource "aws_route_table_association" "private_assoc" {
  count = 3
  subnet_id = element(aws_subnet.private[*].id, count.index)
  route_table_id = element(aws_route_table.private_rt[*].id, count.index)
}
