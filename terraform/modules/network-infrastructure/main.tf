# ==============================
# 🌍 VPC 생성
# ==============================
resource "aws_vpc" "main" {
  cidr_block = var.network_config.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# ==============================
# 🌐 인터넷 게이트웨이 생성
# ==============================
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# ==============================
# 📡 Public Subnet 생성 (AZ 자동 선택)
# ==============================
data "aws_availability_zones" "available" {}

resource "aws_subnet" "public" {
  count = length(var.network_config.public_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.network_config.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-public-${count.index}"
  }
}

# ==============================
# 🔒 Private Subnet 생성 (AZ 자동 선택)
# ==============================
resource "aws_subnet" "private" {
  count = length(var.network_config.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.network_config.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-private-${count.index}"
  }
}

# ==============================
# 📍 Public Route Table 생성
# ==============================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# ==============================
# 🌍 Public Route 추가 (인터넷 연결)
# ==============================
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# ==============================
# 🔗 Public Subnet과 Route Table 연결
# ==============================
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
