# Namespace-scoped Temporal Cloud service account example

Configuration in this directory creates a Temporal Cloud service account confined to a single
namespace, with an API key for a worker fleet to authenticate with.

This is the tighter of the two access models: the service account holds no account-level role and
cannot reach anything outside its namespace. `account_access`, `account_access_custom_roles` and
`namespace_accesses` are all rejected alongside it — see
[Choosing an access model](../../README.md#choosing-an-access-model).

The example also creates the namespace, so it runs with no external setup. In practice that namespace
already exists and only its ID is needed. The region is read from `data.temporalcloud_regions` rather
than hardcoded, because the regions an account may use are a subset of the published list.

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

The namespace assignment is immutable. Pointing `namespace_scoped_access.namespace_id` at a different
namespace replaces the service account and destroys the API key with it, so check the plan for a
replacement before applying.

The API key token is not output here — it is a credential. To read it, add an output of your own marked
`sensitive = true` and use `terraform output -raw`.

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
| <a name="module_service_account"></a> [service\_account](#module\_service\_account) | terraform-temporalcloud-modules/service-account/temporalcloud | ~> 2.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [temporalcloud_namespace.payments](https://registry.terraform.io/providers/temporalio/temporalcloud/latest/docs/resources/namespace) | resource |
| [temporalcloud_regions.available](https://registry.terraform.io/providers/temporalio/temporalcloud/latest/docs/data-sources/regions) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_namespace_grpc_address"></a> [namespace\_grpc\_address](#output\_namespace\_grpc\_address) | The gRPC address a worker using this service account's API key connects to |
| <a name="output_service_account_account_access"></a> [service\_account\_account\_access](#output\_service\_account\_account\_access) | The account-level role. Empty, because a namespace-scoped service account has none |
| <a name="output_service_account_id"></a> [service\_account\_id](#output\_service\_account\_id) | The unique identifier of the service account |
| <a name="output_service_account_namespace_scoped_access"></a> [service\_account\_namespace\_scoped\_access](#output\_service\_account\_namespace\_scoped\_access) | The namespace the service account is confined to, and its permission there |
<!-- END_TF_DOCS -->

## License

Apache-2.0 licensed. See [LICENSE](../../LICENSE).
