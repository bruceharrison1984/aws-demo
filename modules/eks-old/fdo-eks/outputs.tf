output "random_pet" {
  value = random_pet.name.id
}

output "cluster_name" {
  value = module.eks.cluster_name
}
