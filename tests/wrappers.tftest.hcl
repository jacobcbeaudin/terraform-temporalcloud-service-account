// The wrappers submodule: several service accounts from one call, with per-item
// overrides of the shared defaults.
//
// This is the only test that creates more than one service account at a time,
// which is the behaviour it exists to verify.

provider "temporalcloud" {}

run "setup" {
  module {
    source = "./tests/setup"
  }

  // Only names are needed here, and namespace creation is slow.
  variables {
    create_namespace = false
  }
}

run "create_many" {
  module {
    source = "./wrappers"
  }

  variables {
    defaults = {
      account_access = "read"
      description    = "Created by terraform test"
    }

    items = {
      reporting = {
        name = "${run.setup.service_account_name}-reporting"
      }

      workers = {
        name = "${run.setup.service_account_name}-workers"
        // Overrides the shared default above.
        account_access = "developer"

        create_apikey       = true
        apikey_display_name = "${run.setup.service_account_name}-workers-key"
        apikey_expiry_time  = "2027-01-01T00:00:00Z"
      }
    }
  }

  assert {
    condition     = length(output.wrapper) == 2
    error_message = "expected 2 service accounts from the wrapper, got ${length(output.wrapper)}"
  }

  assert {
    condition     = output.wrapper["reporting"].service_account_name == "${run.setup.service_account_name}-reporting"
    error_message = "the reporting item did not take its own name"
  }

  // Shared defaults reach every item.
  assert {
    condition     = lower(output.wrapper["reporting"].service_account_account_access) == "read"
    error_message = "defaults.account_access did not reach the reporting item"
  }

  // Per-item values override the defaults rather than merging with them.
  assert {
    condition     = lower(output.wrapper["workers"].service_account_account_access) == "developer"
    error_message = "the workers item did not override defaults.account_access"
  }

  // Per-item feature gates reach the item too, and only that item.
  assert {
    condition     = output.wrapper["workers"].apikey_id != ""
    error_message = "per-item create_apikey did not reach the workers item"
  }

  assert {
    condition     = output.wrapper["reporting"].apikey_id == ""
    error_message = "the reporting item got an API key it never asked for"
  }
}
