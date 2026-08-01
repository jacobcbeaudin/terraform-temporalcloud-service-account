provider "temporalcloud" {
  # Reads TEMPORAL_CLOUD_API_KEY from the environment.
}

locals {
  name = "ex-${basename(path.cwd)}"
}

################################################################################
# A namespace for the service account to be granted access to
#
# Created here so the example runs with no external setup. In practice this is an
# existing namespace, and only its ID is needed.
#
# The region is read from the account's entitlements rather than hardcoded: the
# regions an account may use are a subset of the published list, and an
# unentitled one is rejected with "is not a valid Temporal Cloud region".
################################################################################

data "temporalcloud_regions" "available" {}

resource "temporalcloud_namespace" "orders" {
  name           = "${local.name}-orders"
  regions        = [sort([for r in data.temporalcloud_regions.available.regions : r.id])[0]]
  retention_days = 1
  api_key_auth   = true
}

################################################################################
# Complete: an account-wide service account, with an API key
#
# `account_access` sets the role the service account holds across the account,
# and `namespace_accesses` grants extra permission on individual namespaces on
# top of it. See the `namespace-scoped` example for the alternative model.
################################################################################

module "service_account" {
  source  = "terraform-temporalcloud-modules/service-account/temporalcloud"
  version = "~> 2.0"

  name        = local.name
  description = "Example service account managed by Terraform"

  # `developer` rather than `owner` or `admin`: those roles implicitly reach every
  # namespace, so the explicit grants below are rejected alongside them.
  account_access = "developer"

  namespace_accesses = [
    {
      namespace_id = temporalcloud_namespace.orders.id
      permission   = "write"
    },
  ]

  # An API key is the only way to obtain usable credentials for a service
  # account, which is why it is managed here rather than in its own module.
  create_apikey       = true
  apikey_display_name = "${local.name}-key"
  apikey_description  = "Example API key managed by Terraform"

  # A fixed timestamp on purpose. Deriving this from timestamp() — for example
  # timeadd(timestamp(), "8760h") — changes the value on every plan, which
  # replaces the key and invalidates credentials already in use.
  apikey_expiry_time = "2027-01-01T00:00:00Z"
}
