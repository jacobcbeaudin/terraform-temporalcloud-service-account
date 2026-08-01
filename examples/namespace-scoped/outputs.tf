output "service_account_id" {
  description = "The unique identifier of the service account"
  value       = module.service_account.service_account_id
}

output "service_account_namespace_scoped_access" {
  description = "The namespace the service account is confined to, and its permission there"
  value       = module.service_account.service_account_namespace_scoped_access
}

output "service_account_account_access" {
  description = "The account-level role. Empty, because a namespace-scoped service account has none"
  value       = module.service_account.service_account_account_access
}

output "namespace_grpc_address" {
  description = "The gRPC address a worker using this service account's API key connects to"
  value       = temporalcloud_namespace.payments.endpoints.grpc_address
}

# The API key token is not output here: it is a credential returned only at
# creation. Read it with `terraform output -raw apikey_token` after adding an
# output of your own marked `sensitive = true`.
