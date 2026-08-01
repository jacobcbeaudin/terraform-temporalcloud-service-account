# Wrapper for the Temporal Cloud service account module

The configuration in `wrappers/` implements the single module wrapper pattern, which allows managing
several copies of this module from one call in places where the native `for_each` on a module block is
not available — most commonly Terragrunt.

This wrapper adds no functionality of its own. Every key under `items` accepts any input the root
module accepts, and `defaults` supplies values shared by all items.

Contributors: see [CONTRIBUTING.md](../CONTRIBUTING.md) for how these files are maintained.

## Usage with Terraform

```hcl
module "service_accounts" {
  source  = "terraform-temporalcloud-modules/service-account/temporalcloud//wrappers"

  # Shared by every item unless the item overrides it.
  defaults = {
    account_access = "read"
    description    = "Managed by Terraform"
  }

  items = {
    reporting = {
      name = "reporting"
    }

    ci = {
      name           = "ci"
      account_access = "developer" # overrides the default above

      create_apikey       = true
      apikey_display_name = "ci"
      apikey_expiry_time  = "2027-01-01T00:00:00Z"
    }

    # The namespace-scoped model works per item too. It cannot be combined with
    # account_access, so this item must not inherit that default — override it
    # to null.
    payments_workers = {
      name           = "payments-workers"
      account_access = null

      namespace_scoped_access = {
        namespace_id = "payments.a1b2c3"
        permission   = "write"
      }
    }
  }
}
```

Outputs are keyed by the same map keys. The wrapper's `wrapper` output is marked sensitive, because the
root module's `apikey_token` is:

```hcl
output "ci_service_account_id" {
  value     = module.service_accounts.wrapper["ci"].service_account_id
  sensitive = true
}
```

## Usage with Terragrunt

`terragrunt.hcl`:

```hcl
terraform {
  source = "tfr:///terraform-temporalcloud-modules/service-account/temporalcloud//wrappers?version=1.0.0"
  # Alternative source:
  # source = "git::git@github.com:terraform-temporalcloud-modules/terraform-temporalcloud-service-account.git//wrappers?ref=v1.0.0"
}

inputs = {
  defaults = {
    account_access = "read"
  }

  items = {
    reporting = { name = "reporting" }
    ci        = { name = "ci", account_access = "developer" }
  }
}
```

Pin `?version=` / `?ref=` to a released tag rather than a branch, so a wrapper upgrade is a deliberate
change.

## Inputs

| Name | Description | Type | Default |
| ---- | ----------- | ---- | ------- |
| `defaults` | Default values applied to every service account in `items`, unless that item overrides them | `any` | `{}` |
| `items` | Map of service accounts to create; each key becomes an instance of the module | `any` | `{}` |

## Outputs

| Name | Description |
| ---- | ----------- |
| `wrapper` | Map of module outputs, keyed by the same keys as `items`. Sensitive, because it carries `apikey_token` |
