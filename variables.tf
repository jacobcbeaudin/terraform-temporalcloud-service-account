variable "create_service_account" {
  description = "Controls if the service account should be created. Set to `false` to disable the module without removing the call"
  type        = bool
  default     = true
}

################################################################################
# Service account
################################################################################

variable "name" {
  description = "The name of the service account. Required unless `create_service_account` is `false`"
  type        = string
  default     = ""
}

variable "description" {
  description = "Description of the service account. Shown alongside it in the Temporal Cloud UI"
  type        = string
  default     = null
}

################################################################################
# Account-wide access
#
# `account_access`, `account_access_custom_roles` and `namespace_accesses` form
# one access model; `namespace_scoped_access` below is the other. Exactly one of
# the two must be used.
################################################################################

variable "account_access" {
  description = "The role this service account holds on the account: `owner`, `admin`, `developer`, `read`, `financeadmin` or `metricsread`, matched case-insensitively. Set this or `namespace_scoped_access`, never both"
  type        = string
  default     = null

  # try() covers the null case: lower() raises on a null argument, so the whole
  # check is wrapped rather than guarded operand by operand.
  validation {
    condition     = try(contains(["owner", "admin", "developer", "read", "financeadmin", "metricsread"], lower(var.account_access)), true)
    error_message = "Account access must be one of: owner, admin, developer, read, financeadmin, metricsread (case-insensitive)."
  }
}

variable "account_access_custom_roles" {
  description = "IDs of custom roles granted in addition to the built-in `account_access` role. Omit rather than passing an empty set. Cannot be combined with `namespace_scoped_access`"
  type        = set(string)
  default     = null

  validation {
    condition     = try(length(var.account_access_custom_roles) > 0, true)
    error_message = "Empty sets are not accepted by the provider. Omit the variable instead."
  }
}

variable "namespace_accesses" {
  description = "Per-namespace permissions, as a set of `namespace_id` and `permission` pairs. `permission` is `admin`, `write` or `read`, matched case-insensitively. A service account whose `account_access` is `owner` or `admin` already reaches every namespace and cannot be given explicit entries here. Omit rather than passing an empty set. Cannot be combined with `namespace_scoped_access`"
  type = set(object({
    namespace_id = string
    permission   = string
  }))
  default = null

  validation {
    condition     = try(length(var.namespace_accesses) > 0, true)
    error_message = "Empty sets are not accepted by the provider. Omit the variable instead."
  }

  validation {
    condition = try(alltrue([
      for access in var.namespace_accesses :
      contains(["admin", "write", "read"], lower(access.permission))
    ]), true)
    error_message = "Namespace access permissions must be one of: admin, write, read (case-insensitive)."
  }
}

################################################################################
# Namespace-scoped access
#
# The alternative access model: a service account confined to a single namespace,
# with no account-level role at all.
################################################################################

variable "namespace_scoped_access" {
  description = "Confines the service account to exactly one namespace, with no account-level role. `permission` is `admin`, `write` or `read`, matched case-insensitively, and can be changed later; `namespace_id` cannot, so changing it replaces the service account and every API key issued for it. Set this or `account_access`, never both"
  type = object({
    namespace_id = string
    permission   = string
  })
  default = null

  validation {
    condition     = try(contains(["admin", "write", "read"], lower(var.namespace_scoped_access.permission)), true)
    error_message = "Namespace-scoped permission must be one of: admin, write, read (case-insensitive)."
  }
}

variable "timeouts" {
  description = "Create and delete timeouts for the service account, as duration strings such as `30s` or `2h45m`"
  type = object({
    create = optional(string)
    delete = optional(string)
  })
  default = {}
}

################################################################################
# API key
#
# Managed here rather than as a separate module: a key is issued for a service
# account and is the only way to get usable credentials out of one.
################################################################################

variable "create_apikey" {
  description = "Controls if an API key should be issued for the service account. Has no effect when `create_service_account` is `false`, since the key needs an owner"
  type        = bool
  default     = false
}

variable "apikey_display_name" {
  description = "Display name of the API key, shown in the Temporal Cloud UI. Required when `create_apikey` is `true`"
  type        = string
  default     = ""
}

variable "apikey_description" {
  description = "Description of the API key"
  type        = string
  default     = null
}

variable "apikey_expiry_time" {
  description = "When the API key expires, as an RFC 3339 timestamp such as `2027-01-01T00:00:00Z`. Required when `create_apikey` is `true`. Use a fixed timestamp: an expression derived from `timestamp()` changes on every plan and replaces the key, invalidating credentials already in use"
  type        = string
  default     = ""

  # formatdate() parses RFC 3339 and nothing else, so it accepts exactly the
  # strings the provider parses at apply time and rejects the rest here, naming
  # the variable.
  validation {
    condition     = var.apikey_expiry_time == "" || can(formatdate("YYYY-MM-DD", var.apikey_expiry_time))
    error_message = "The API key expiry time must be an RFC 3339 timestamp, for example 2027-01-01T00:00:00Z."
  }
}

variable "apikey_disabled" {
  description = "Disables the API key without deleting it. A disabled key is rejected at authentication but keeps its identity, so it can be re-enabled"
  type        = bool
  default     = null
}

variable "apikey_timeouts" {
  description = "Create and delete timeouts for the API key, as duration strings such as `30s` or `2h45m`"
  type = object({
    create = optional(string)
    delete = optional(string)
  })
  default = {}
}
