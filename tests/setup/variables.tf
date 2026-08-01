variable "create_namespace" {
  description = "Controls if a namespace is created for the run to grant access on. Left off by tests that only exercise account-level access, because namespace creation is slow"
  type        = bool
  default     = true
}
