output "wrapper" {
  description = "Map of module outputs, keyed by the same keys as `items`"
  value       = module.wrapper
  # The root module's apikey_token output is sensitive, so the whole map is.
  # Read a single value out of it with nonsensitive() only where that is safe.
  sensitive = true
}
