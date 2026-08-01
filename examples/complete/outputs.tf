output "service_account_id" {
  description = "The unique identifier of the service account"
  value       = module.service_account.service_account_id
}

output "service_account_account_access" {
  description = "The account-level role held by the service account"
  value       = module.service_account.service_account_account_access
}

output "service_account_namespace_accesses" {
  description = "The per-namespace permissions granted to the service account"
  value       = module.service_account.service_account_namespace_accesses
}

output "apikey_id" {
  description = "The unique identifier of the API key"
  value       = module.service_account.apikey_id
}

# The token itself is deliberately not surfaced here. It is a credential, it is
# returned only at creation, and an output would print it into any plan or apply
# log that renders this example. Read it on demand instead:
#
#   terraform output -raw apikey_token
#
# after adding an output of your own marked `sensitive = true`.
