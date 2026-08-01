# Complete Temporal Cloud service account example

Configuration in this directory creates a Temporal Cloud service account with an account-level role, an
explicit permission on one namespace, and an API key.

It also creates the namespace the grant points at, so the example runs with no external setup. In
practice that namespace already exists and only its ID is needed. The region is read from
`data.temporalcloud_regions` rather than hardcoded, because the regions an account may use are a subset
of the published list.

See [Choosing an access model](../../README.md#choosing-an-access-model) for when to use this shape
instead of [namespace-scoped](../namespace-scoped).

## Usage

To run this example you need to execute:

```bash
export TEMPORAL_CLOUD_API_KEY="<your-api-key>"

terraform init
terraform plan
terraform apply
```

Note that this example creates resources which cost money. Run `terraform destroy` when you no longer
need them.

The API key token is deliberately not output here — it is a credential, and an output would render it
into any plan or apply log. To read it, add an output of your own marked `sensitive = true` and use
`terraform output -raw`.

`apikey_expiry_time` is a fixed timestamp on purpose. Deriving it from `timestamp()` changes the value
on every plan, which replaces the key and invalidates credentials already in use.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_temporalcloud"></a> [temporalcloud](#requirement\_temporalcloud) | >= 1.6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_temporalcloud"></a> [temporalcloud](#provider\_temporalcloud) | >= 1.6.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_service_account"></a> [service\_account](#module\_service\_account) | terraform-temporalcloud-modules/service-account/temporalcloud | ~> 1.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [temporalcloud_namespace.orders](https://registry.terraform.io/providers/temporalio/temporalcloud/latest/docs/resources/namespace) | resource |
| [temporalcloud_regions.available](https://registry.terraform.io/providers/temporalio/temporalcloud/latest/docs/data-sources/regions) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_apikey_id"></a> [apikey\_id](#output\_apikey\_id) | The unique identifier of the API key |
| <a name="output_service_account_account_access"></a> [service\_account\_account\_access](#output\_service\_account\_account\_access) | The account-level role held by the service account |
| <a name="output_service_account_id"></a> [service\_account\_id](#output\_service\_account\_id) | The unique identifier of the service account |
| <a name="output_service_account_namespace_accesses"></a> [service\_account\_namespace\_accesses](#output\_service\_account\_namespace\_accesses) | The per-namespace permissions granted to the service account |
<!-- END_TF_DOCS -->

## License

Apache-2.0 licensed. See [LICENSE](../../LICENSE).
