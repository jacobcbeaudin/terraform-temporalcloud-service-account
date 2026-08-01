// The other access model: a service account confined to a single namespace.
//
// A separate file so it gets its own state and its own service account. Files
// run sequentially and each is torn down before the next begins.
//
// It has to be separate for a second reason: the provider rejects
// namespace_scoped_access alongside account_access at validate time, so this
// cannot be reached by updating the service account in service_account.tftest.hcl.

provider "temporalcloud" {}

run "setup" {
  module {
    source = "./tests/setup"
  }

  // namespace_scoped_access needs a real namespace ID.
  variables {
    create_namespace = true
  }
}

run "create_namespace_scoped_service_account" {
  variables {
    name        = "${run.setup.service_account_name}-scoped"
    description = "Namespace-scoped, created by terraform test"

    namespace_scoped_access = {
      namespace_id = run.setup.namespace_id
      permission   = "write"
    }

    // A namespace-scoped service account still gets credentials the same way.
    create_apikey       = true
    apikey_display_name = "${run.setup.service_account_name}-scoped-key"
    apikey_expiry_time  = "2027-01-01T00:00:00Z"
  }

  assert {
    condition     = output.service_account_id != ""
    error_message = "service_account_id is empty, so the service account was not created"
  }

  assert {
    condition     = output.service_account_namespace_scoped_access.namespace_id == run.setup.namespace_id
    error_message = "namespace_scoped_access did not come back pointing at the namespace created for this run"
  }

  assert {
    condition     = lower(output.service_account_namespace_scoped_access.permission) == "write"
    error_message = "the namespace-scoped permission did not round-trip through the API"
  }

  // The point of this model: no account-level role at all.
  assert {
    condition     = output.service_account_account_access == ""
    error_message = "a namespace-scoped service account reported an account-level role: ${output.service_account_account_access}"
  }

  assert {
    condition     = output.apikey_token != ""
    error_message = "apikey_token is empty, so the key produced no usable credential"
  }
}

// The permission is mutable even though the namespace assignment is not, so
// narrowing it must update the service account in place rather than replace it.
run "narrow_permission" {
  variables {
    name        = "${run.setup.service_account_name}-scoped"
    description = "Namespace-scoped, created by terraform test"

    namespace_scoped_access = {
      namespace_id = run.setup.namespace_id
      permission   = "read"
    }

    create_apikey       = true
    apikey_display_name = "${run.setup.service_account_name}-scoped-key"
    apikey_expiry_time  = "2027-01-01T00:00:00Z"
  }

  assert {
    condition     = lower(output.service_account_namespace_scoped_access.permission) == "read"
    error_message = "the namespace-scoped permission was not narrowed to read"
  }

  // The ID, not the name: both runs request the same name, so only the ID can
  // tell an in-place update from a replacement.
  assert {
    condition     = output.service_account_id == run.create_namespace_scoped_service_account.service_account_id
    error_message = "service account was replaced rather than updated in place"
  }
}
