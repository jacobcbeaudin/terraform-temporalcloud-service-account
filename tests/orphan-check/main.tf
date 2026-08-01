# Reports test resources still present in the account.
#
# Creates nothing: data sources and outputs only. `terraform test` destroys what
# it creates, but a cancelled or crashed run can leave something behind, and
# nothing else would notice.
#
# Run after the apply tests. Anything reported here is a leftover.
#
# Two resource kinds are checked. API keys are a third, and cannot be: the
# provider exposes no data source for them. A key belongs to a service account,
# so a run that leaks a key normally leaks its owner too and is caught by the
# service account check below. If a service account is reported here, delete it
# and its keys go with it.

data "temporalcloud_service_accounts" "all" {}

data "temporalcloud_namespaces" "all" {}

locals {
  orphan_service_accounts = [
    for sa in data.temporalcloud_service_accounts.all.service_accounts : sa.name
    if startswith(sa.name, var.test_resource_prefix)
  ]

  # The suite creates a namespace as a fixture, so a leaked namespace is just as
  # possible as a leaked service account.
  orphan_namespaces = [
    for ns in data.temporalcloud_namespaces.all.namespaces : ns.name
    if startswith(ns.name, var.test_resource_prefix)
  ]

  orphans = concat(local.orphan_service_accounts, local.orphan_namespaces)
}
