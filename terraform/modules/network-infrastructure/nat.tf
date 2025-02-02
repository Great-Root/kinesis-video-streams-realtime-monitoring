# NAT 게이트웨이용 탄력적 IP
resource "aws_eip" "nat" {
  count = var.network_config.enable_nat_gateway ? 1 : 0
  domain = "vpc"
}

# NAT 게이트웨이 생성 (필요할 경우)
resource "aws_nat_gateway" "nat" {
  count = var.network_config.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-gateway"
  }
}

# 사설 라우트 테이블 생성
resource "aws_route_table" "private" {
  count = var.network_config.enable_nat_gateway ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt"
  }
}

# NAT 게이트웨이를 통한 기본 라우트 추가 (사설 서브넷 → 인터넷)
resource "aws_route" "private_nat_access" {
  count = var.network_config.enable_nat_gateway ? 1 : 0

  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[0].id
}

# 사설 서브넷을 사설 라우트 테이블과 연결
resource "aws_route_table_association" "private" {
  count = var.network_config.enable_nat_gateway ? length(var.network_config.private_subnet_cidrs) : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}
