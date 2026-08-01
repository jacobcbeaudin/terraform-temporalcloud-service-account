// Main lifecycle: create a service account with an account-level role, then
// update it in place to add per-namespace permissions and issue an API key.
//
// Creates ONE service account and updates it across run blocks rather than one
// per case. Run blocks share state within a file, so a later block with
// different variables updates the service account instead of creating another —
// which also proves the folded-in API key attaches to an existing parent.
//
// terraform test destroys everything it created when the file finishes,
// including after a failed assertion.

provider "temporalcloud" {
  // Reads TEMPORAL_CLOUD_API_KEY from the environment. The module under test
  // declares no provider block, by design for a published module, so the test
  // supplies one.
}

run "setup" {
  module {
    source = "./tests/setup"
  }

  // namespace_accesses needs a real namespace ID, so this run creates one.
  variables {
    create_namespace = true
  }
}

run "create_service_account" {
  variables {
    name        = run.setup.service_account_name
    description = "Created by terraform test"

    // `developer`, not `admin`: an admin service account implicitly reaches
    // every namespace, and the API then refuses the explicit grants added in
    // the next run block.
    account_access = "developer"

    timeouts = {
      create = "10m"
      delete = "10m"
    }
  }

  assert {
    condition     = output.service_account_id != ""
    error_message = "service_account_id is empty, so the service account was not created"
  }

  assert {
    condition     = output.service_account_name == run.setup.service_account_name
    error_message = "service_account_name output did not echo the requested name"
  }

  assert {
    condition     = lower(output.service_account_account_access) == "developer"
    error_message = "account_access did not round-trip through the API, got: ${output.service_account_account_access}"
  }

  assert {
    condition     = output.service_account_state != ""
    error_message = "service_account_state is empty"
  }

  // Nothing requested yet.
  assert {
    condition     = length(output.service_account_namespace_accesses) == 0
    error_message = "expected no namespace accesses before any were requested"
  }

  assert {
    condition     = output.apikey_id == ""
    error_message = "an API key was created despite create_apikey defaulting to false"
  }
}

// Updates the SAME service account: adds a namespace grant and issues the API
// key this module folds in.
run "add_namespace_access_and_apikey" {
  variables {
    name           = run.setup.service_account_name
    description    = "Created by terraform test"
    account_access = "developer"

    timeouts = {
      create = "10m"
      delete = "10m"
    }

    namespace_accesses = [
      {
        namespace_id = run.setup.namespace_id
        permission   = "write"
      },
    ]

    create_apikey       = true
    apikey_display_name = "${run.setup.service_account_name}-key"
    apikey_description  = "Created by terraform test"

    // A fixed timestamp on purpose: an expiry derived from timestamp() changes
    // on every plan and would replace the key between run blocks.
    apikey_expiry_time = "2027-01-01T00:00:00Z"
    apikey_disabled    = false
  }

  // Updating must not have replaced the service account. The ID is what proves
  // that: the name is the same in both runs by construction, so comparing it
  // would pass either way.
  assert {
    condition     = output.service_account_id == run.create_service_account.service_account_id
    error_message = "service account was replaced rather than updated in place"
  }

  // Elementwise, not ==: the output comes from try(..., []) so it is a tuple,
  // which never compares equal to a list.
  assert {
    condition     = length(output.service_account_namespace_accesses) == 1
    error_message = "expected 1 namespace access, got ${length(output.service_account_namespace_accesses)}"
  }

  assert {
    condition     = tolist(output.service_account_namespace_accesses)[0].namespace_id == run.setup.namespace_id
    error_message = "the namespace access did not come back pointing at the namespace created for this run"
  }

  assert {
    condition     = lower(tolist(output.service_account_namespace_accesses)[0].permission) == "write"
    error_message = "the namespace permission did not round-trip through the API"
  }

  assert {
    condition     = output.apikey_id != ""
    error_message = "apikey_id is empty despite create_apikey = true"
  }

  assert {
    condition     = output.apikey_display_name == "${run.setup.service_account_name}-key"
    error_message = "apikey_display_name output did not echo the requested display name"
  }

  assert {
    condition     = output.apikey_state != ""
    error_message = "apikey_state is empty"
  }

  // The reason the API key is folded into this module: it is the only way to get
  // usable credentials out of a service account, and the token is returned once,
  // at creation.
  assert {
    condition     = output.apikey_token != ""
    error_message = "apikey_token is empty, so the key produced no usable credential"
  }
}

// Narrows the account role and the namespace permission, keeping the same
// service account and API key.
run "reduce_access" {
  variables {
    name           = run.setup.service_account_name
    description    = "Narrowed by terraform test"
    account_access = "read"

    timeouts = {
      create = "10m"
      delete = "10m"
    }

    namespace_accesses = [
      {
        namespace_id = run.setup.namespace_id
        permission   = "read"
      },
    ]

    create_apikey       = true
    apikey_display_name = "${run.setup.service_account_name}-key"
    apikey_description  = "Created by terraform test"
    apikey_expiry_time  = "2027-01-01T00:00:00Z"

    // Disabling a key keeps its identity, so the ID must survive this change.
    apikey_disabled = true
  }

  assert {
    condition     = lower(output.service_account_account_access) == "read"
    error_message = "account_access was not narrowed to read"
  }

  assert {
    condition     = lower(tolist(output.service_account_namespace_accesses)[0].permission) == "read"
    error_message = "namespace permission was not narrowed to read"
  }

  assert {
    condition     = output.service_account_id == run.create_service_account.service_account_id
    error_message = "service account was replaced rather than updated in place"
  }

  assert {
    condition     = output.apikey_id == run.add_namespace_access_and_apikey.apikey_id
    error_message = "disabling the API key replaced it instead of disabling it"
  }
}
