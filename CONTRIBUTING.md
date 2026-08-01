# Contributing

## Prerequisites

```bash
brew install pre-commit terraform-docs
brew install terraform-linters/tap/tflint
pre-commit install
```

Local tool versions must match the pins in
[`.github/workflows/pre-commit.yml`](.github/workflows/pre-commit.yml). terraform-docs changed its
markdown table style after v0.20.0, so a mismatch makes CI reject README tables that were generated
correctly on your machine. When you bump one side, bump the other in the same pull request.

## The gate

```bash
pre-commit run -a
```

This is what CI runs: `terraform fmt`, `terraform-docs`, `tflint`, `terraform validate`, plus two local
checks described below. Expect the first run after a change to *modify* files — terraform-docs rewrites
the README tables. Re-run until clean; it should pass twice in a row.

## Test layers

| Path | Runs on | Credentials | Proves |
| --- | --- | --- | --- |
| `examples/*` | every PR | no | The documented usage still type-checks against this code |
| `tests/local/` | every PR | no | Every input and output is still valid |
| `tests/*.tftest.hcl` | on demand, weekly | **yes** | Temporal Cloud accepts the payloads this module sends |

`terraform validate` is not a test: it never executes anything and never contacts the API. Only the
apply layer can catch the API rejecting a configuration that looks valid.

`terraform plan` is not a usable middle ground, because the provider authenticates when it initialises
and so needs a real key even for a plan that would create nothing.

### Why examples are validated indirectly

`examples/*` source the **published** module so consumers can copy them verbatim from the Terraform
Registry. Validating them as written would check the last release rather than the working tree, which
would mean a module change and its example update could never land in the same pull request.

[`scripts/validate-examples.sh`](scripts/validate-examples.sh) resolves this: it copies each example to
a temporary directory, rewrites the registry source to a path to the repository root, and validates the
copy. Tracked files are never modified. `terraform_validate` excludes `examples/`, and the
`examples-validate` hook covers them instead.

The rewrite only understands this module's own registry address, and the script fails if any
`terraform-temporalcloud-modules/` source survives it. An example therefore cannot call another module
in this family — where one needs a namespace, it creates a `temporalcloud_namespace` resource directly.

One consequence: examples are validated only on the maximum supported Terraform version, because the
exclusion also removes them from the minimum-version matrix jobs. The root module and `tests/local/`
are still checked against the minimum, which is what `required_version` asserts.

### Why `wrappers/` is hand-maintained

The upstream `terraform_wrapper_module_for_each` pre-commit hook is not enabled. It hardcodes
`terraform-aws-modules` and `aws` in the source addresses it generates, and it overwrites
`wrappers/README.md` on every run with an Amazon S3 example whose inputs do not exist in this module.
It offers no way to skip that file, so restoring a correct one leaves the gate permanently dirty.

[`scripts/check-wrapper-sync.sh`](scripts/check-wrapper-sync.sh) replaces the one useful thing the hook
did: it fails if a root variable is not passed through `wrappers/main.tf`. When you add a variable to
the root module, add the matching line to the wrapper in the same change.

## Why validation is where it is

The module's `variable` blocks validate each value in isolation — permitted role names, permitted
permissions, RFC 3339 expiry timestamps, non-empty sets. These name the *variable* a consumer set,
which the provider's own errors cannot do.

The relationships between the two access models are **not** re-implemented here, deliberately:

- The provider carries `ConflictsWith` validators for `namespace_scoped_access` against
  `account_access`, `account_access_custom_roles` and `namespace_accesses`. They fire during
  `terraform validate`, before any module-level check could, with `Invalid Attribute Combination` and
  the two attribute names. A module-level duplicate would be unreachable.
- Requiring one of the two is enforced by the API at apply, with
  `Either account_access or namespace_scoped_access must be provided`.

Cross-variable checks would in any case need `precondition` blocks rather than `validation` blocks:
referencing another variable inside `variable ... validation` requires Terraform 1.9, and
`required_version` here is `>= 1.5.7`. Raising that floor to restate a check the provider already
performs is not worth locking consumers out.

When you do add a `validation`, wrap the **whole** condition in `try(<check>, true)` rather than
guarding operand by operand. `||` short-circuits in HCL, but functions inside a condition still raise
on null arguments — `lower(null)` and `length(null)` both error. Verify each new validation against all
four cases: variable null, attribute omitted, attribute valid, attribute invalid.

## API behaviours the tests guard against

Each of these either fails only on apply, or fails silently. They are the reason the apply layer
exists.

1. **`namespace_scoped_access.namespace_id` is immutable.** `namespace_scoped.tftest.hcl` changes only
   the permission between run blocks and asserts that `service_account_id` is unchanged, which is what
   distinguishes an in-place update from a replacement — the name cannot, since both runs request the
   same one.
2. **`create_apikey` is subordinate to `create_service_account`.** A key needs an owner.
   `disabled.tftest.hcl` sets `create_apikey = true` with the service account off and asserts nothing
   is created.
3. **An expiry derived from `timestamp()` replaces the key on every apply.** `expiry_time` carries
   `RequiresReplace` in the provider, and `timestamp()` produces a new value on every plan. Nothing
   errors; the credential in use is simply invalidated. The tests and examples use fixed timestamps,
   and the variable description says why.

Two more are caught earlier than that, by provider-side validators, and so need no apply run:
`account_access` of `owner` or `admin` alongside explicit `namespace_accesses`, and the two access
models set together. Both fail during `terraform validate`.

When writing assertions, note that outputs wrapped in `try(x, [])` evaluate to a *tuple*, so
`output.service_account_namespace_accesses == tolist([])` is false even against an empty result.
Compare with `length()` and index elementwise instead.

`apikey_token` is a sensitive output, and so is the wrapper's `wrapper` output. Comparing either in an
`assert` condition works and needs no `nonsensitive()`. Interpolating one into `error_message` does
not: Terraform suppresses the rendered message with `Error message refers to sensitive values`, so
wrap the interpolated part in `nonsensitive()` or keep the message static.

## Running the apply tests

They create and destroy **real, billable** service accounts, API keys and namespaces. Point them at a
scratch account.

```bash
export TEMPORAL_CLOUD_API_KEY="<key for a scratch account>"
terraform init
terraform test -verbose
```

Without a key every run block is skipped, which is a cheap way to check that the test files parse:

```text
Failure! 0 passed, 0 failed, 10 skipped.
```

In CI they run from the **Apply Tests** workflow. Its first step is
[`scripts/check-api.sh`](scripts/check-api.sh), a liveness check that confirms the API answers and the
key is accepted, so a credentials problem fails immediately rather than surfacing minutes later as a
resource that would not create.

Apply Tests is chained after Pre-Commit, and Release after Apply Tests, so a merge to main runs:

```text
push to main -> Pre-Commit -> Apply Tests -> Release
```

A release is therefore only cut from code that passed both the static gate and the tests that apply
against a real account. Any failure in the chain stops it.

Apply Tests never runs on pull requests: forks cannot read secrets and every run costs money. It also
runs weekly, and on demand. Runs are serialized with `cancel-in-progress: false`, because cancelling
mid-apply would abandon resources with no destroy.

Resources created by the tests are prefixed so leftovers from an interrupted run are identifiable; see
[`tests/README.md`](tests/README.md).

## Pull requests

Titles must be [conventional commits](https://www.conventionalcommits.org/) — `feat:`, `fix:`, `docs:`,
`ci:`, `chore:` — with a capitalised subject. Squash-merge makes the title the commit message, and
semantic-release derives the next version from it, so an invalid title silently breaks versioning. A
workflow enforces this.

`CHANGELOG.md` and tags are generated on merge. Never bump versions by hand.

If CI reports fewer checks than usual, check whether the pull request has merge conflicts: GitHub skips
`pull_request` workflows when it cannot compute a merge ref, with no failed check to show for it.
