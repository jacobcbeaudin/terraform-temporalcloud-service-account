# Tests

Not usage examples — see [examples/](../examples) for those.

| Path | Runs on | Credentials |
| --- | --- | --- |
| `local/` | every pull request | no |
| `*.tftest.hcl` | on demand, weekly | **yes** |
| `setup/` | helper for `*.tftest.hcl` | no |

`local/` passes every module input and references every output, so `terraform
validate` fails there as soon as the variable surface changes.

`*.tftest.hcl` applies against a real Temporal Cloud account, which is the only
way to catch the API rejecting a configuration that type-checks.

| File | Covers |
| --- | --- |
| `service_account.tftest.hcl` | Create with an account-level role and timeouts; update in place to add `namespace_accesses` and issue an API key; update again to narrow both roles and disable the key |
| `namespace_scoped.tftest.hcl` | `namespace_scoped_access` with an API key, asserting no account-level role comes back; then narrowing the permission in place |
| `wrappers.tftest.hcl` | The `wrappers` submodule: two service accounts from one call, with per-item overrides and a per-item API key |
| `disabled.tftest.hcl` | `create_service_account = false` creates nothing — including no API key, despite `create_apikey = true` — and every output falls back |

Fixtures: `setup/` generates a unique name and, when asked, creates the namespace
that `namespace_accesses` and `namespace_scoped_access` point at. Both take a real
namespace ID, so the suite has to create one. It is gated behind
`create_namespace` because namespace creation is slow and `wrappers.tftest.hcl`
only needs names. `liveness/` and `orphan-check/` create nothing.

## What is not apply-tested

`account_access_custom_roles` is covered only by `local/`. Applying it needs a
`temporalcloud_custom_role`, which belongs to a different module in this family;
creating one here would couple this suite to that resource's own constraints. To
run it by hand, create a custom role in the account, then add its ID to the
`create_service_account` run block in `service_account.tftest.hcl`.

Files run sequentially and each is torn down before the next begins, so only
`wrappers.tftest.hcl` has more than one service account alive at a time.

[CONTRIBUTING.md](../CONTRIBUTING.md) explains why the layers are split this way
and which API behaviours they guard against.

## Running the apply tests

```bash
export TEMPORAL_CLOUD_API_KEY="<key for a scratch account>"
terraform init
terraform test -verbose
```

Point them at a scratch account: they create and destroy **real, billable**
service accounts, API keys and namespaces.

Without a key, every run block is skipped — a cheap way to confirm the test files
parse:

```text
Failure! 0 passed, 0 failed, 10 skipped.
```

## Cleaning up leftovers

`terraform test` destroys what it created, including after a failed assertion, but
a cancelled or crashed run can orphan a resource. The CI workflow therefore runs
`scripts/check-orphans.sh` afterwards — always, including when the tests fail,
since that is when something is most likely to be left behind. It fails the job and
names anything still present. Run it by hand the same way:

```bash
scripts/check-orphans.sh
```

It checks service accounts and namespaces. API keys are not checked and cannot be:
the provider exposes no data source for them. A key belongs to a service account,
so deleting a reported leftover removes its keys with it.

Test resources are prefixed so they are identifiable:

| Prefix | Created by |
| --- | --- |
| `yulei-tftest-sa-<random>` | `*.tftest.hcl`, both service accounts and the namespace fixture |
| `yulei-tflocal-*` | `local/`, only if applied by hand — CI never applies it |

Anything matching those prefixes that no live configuration owns can be deleted.

The `examples/` directories are not covered by this prefix; they create
`ex-complete` and `ex-namespace-scoped`, plus a namespace each. Example code is
published to the Terraform Registry, so it carries no test-specific naming. Check
for those separately if you have applied an example by hand.
