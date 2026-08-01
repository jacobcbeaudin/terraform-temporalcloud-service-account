# Generates unique names for a test run, and — when asked — a namespace for the
# access tests to grant permissions on.
#
# Service accounts created by the suite are identified by a fixed prefix so a
# leftover from an interrupted run can be told apart from anything created by
# hand. A random suffix keeps a second or concurrent run from colliding with the
# first.
resource "random_pet" "this" {
  length    = 2
  separator = "-"
}

# Regions this account is entitled to use.
#
# Not hardcoded: the regions an account may use are a subset of the published
# list, so a fixed ID makes the suite account-specific and can fail with
# "is not a valid Temporal Cloud region".
data "temporalcloud_regions" "available" {}

locals {
  # Sorted so repeat runs pick the same region and results stay comparable.
  region_ids = sort([for r in data.temporalcloud_regions.available.regions : r.id])
}

# A namespace for `namespace_accesses` and `namespace_scoped_access` to point at.
# Both take a real namespace ID that must exist, so the suite has to create one.
#
# Gated because namespace creation is slow and the tests that only exercise
# account-level access do not need one.
resource "temporalcloud_namespace" "this" {
  count = var.create_namespace ? 1 : 0

  name           = "yulei-tftest-sa-${random_pet.this.id}"
  regions        = [local.region_ids[0]]
  retention_days = 1
  api_key_auth   = true
}
