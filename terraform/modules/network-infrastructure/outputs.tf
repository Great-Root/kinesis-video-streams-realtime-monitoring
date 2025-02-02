output "vpc_id" {
  description = "생성된 VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public Subnet ID 목록"
  value       = {
    "public1" = aws_subnet.public[0].id
    "public2" = aws_subnet.public[1].id
  }
}


output "private_subnet_ids" {
  description = "사설 서브넷 ID 목록"
  value       = { for idx, subnet in aws_subnet.private : "private${idx + 1}" => subnet.id }
}

output "internet_gateway_id" {
  description = "인터넷 게이트웨이 ID"
  value       = aws_internet_gateway.igw.id
}

output "nat_gateway_id" {
  description = "NAT 게이트웨이 ID (활성화된 경우)"
  value       = var.network_config.enable_nat_gateway ? aws_nat_gateway.nat[0].id : null
}
