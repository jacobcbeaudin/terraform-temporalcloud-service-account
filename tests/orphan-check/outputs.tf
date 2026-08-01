output "orphans" {
  description = "Names of test service accounts and namespaces still present in the account"
  value       = local.orphans
}

output "orphan_count" {
  description = "Number of test resources still present"
  value       = length(local.orphans)
}
