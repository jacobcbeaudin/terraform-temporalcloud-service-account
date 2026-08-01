provider "temporalcloud" {
  # Reads TEMPORAL_CLOUD_API_KEY from the environment.
}

locals {
  name = "ex-${basename(path.cwd)}"
}

################################################################################
# The namespace this service account will be confined to
#
# Created here so the example runs with no external setup. In practice this is an
# existing namespace, and only its ID is needed.
#
# The region is read from the account's entitlements rather than hardcoded: the
# regions an account may use are a subset of the published list, and an
# unentitled one is rejected with "is not a valid Temporal Cloud region".
################################################################################

data "temporalcloud_regions" "available" {}

resource "temporalcloud_namespace" "payments" {
  name           = "${local.name}-payments"
  regions        = [sort([for r in data.temporalcloud_regions.available.regions : r.id])[0]]
  retention_days = 1
  api_key_auth   = true
}

################################################################################
# A namespace-scoped service account
#
# This is the tighter of the two access models: the service account exists only
# within one namespace and holds no account-level role, so it cannot enumerate or
# reach anything else in the account. Use it for a worker fleet that serves a
# single namespace.
#
# `account_access`, `account_access_custom_roles` and `namespace_accesses` are all
# rejected alongside it — see the `complete` example for that model.
#
# The namespace assignment is immutable. Pointing this at a different namespace
# replaces the service account, which also invalidates the API key below.
################################################################################

module "service_account" {
  source  = "terraform-temporalcloud-modules/service-account/temporalcloud"
  version = "~> 1.0"

  name        = local.name
  description = "Worker fleet for the payments namespace"

  namespace_scoped_access = {
    namespace_id = temporalcloud_namespace.payments.id
    permission   = "write"
  }

  create_apikey       = true
  apikey_display_name = "${local.name}-worker-key"

  # A fixed timestamp on purpose — see the note in the complete example.
  apikey_expiry_time = "2027-01-01T00:00:00Z"
}
