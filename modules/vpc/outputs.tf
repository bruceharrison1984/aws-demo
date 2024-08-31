output "database_subnets" {
  value = module.vpc.database_subnets
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "vpc_name" {
  value = module.vpc.name
}
