resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_vpc
  tags       = merge(var.tags, { "Name" = var.vpc_name })
}

resource "aws_subnet" "subnet-1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.cidr_subnet_1
  map_public_ip_on_launch = true
  tags                    = merge(var.tags, { "Name" = var.subnet_name_1 })
}

resource "aws_subnet" "subnet-2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.cidr_subnet_2
  # Must be true to allow install packages
  map_public_ip_on_launch = true
  tags                    = merge(var.tags, { "Name" = var.subnet_name_2 })
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { "Name" = var.subnet_name_1 })
}

resource "aws_route_table" "rt01" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = var.tags
}

resource "aws_route_table_association" "rt-assoc-02" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.rt01.id
}

resource "aws_route_table_association" "rt-assoc-01" {
  subnet_id      = aws_subnet.subnet-2.id
  route_table_id = aws_route_table.rt01.id
}
