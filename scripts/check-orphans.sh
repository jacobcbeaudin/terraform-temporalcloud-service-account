#!/usr/bin/env bash
#
# Fails if the test suite left service accounts or namespaces behind.
#
# `terraform test` destroys what it created, including after a failed assertion,
# but a cancelled or crashed run can orphan a resource and nothing else would
# notice. Run this after the apply tests.
#
# API keys are not checked: the provider exposes no data source for them. A key
# belongs to a service account, so deleting a leftover service account removes
# its keys with it.
#
# Requires TEMPORAL_CLOUD_API_KEY. Creates nothing — tests/orphan-check contains
# data sources and outputs only.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)/tests/orphan-check"

terraform init -backend=false -no-color >/dev/null
terraform apply -auto-approve -no-color >/dev/null

count="$(terraform output -raw orphan_count)"

if [ "$count" -eq 0 ]; then
  echo "No leftover test resources."
  exit 0
fi

echo "ERROR: $count test resource(s) still present after the suite finished:" >&2
terraform output -json orphans | sed 's/[][",]/ /g' | tr -s ' ' '\n' | sed '/^$/d;s/^/  - /' >&2
echo >&2
echo "These were not destroyed. Delete them in the Temporal Cloud UI, or import and" >&2
echo "destroy them. Deleting a service account also removes any API keys issued for" >&2
echo "it." >&2
exit 1
