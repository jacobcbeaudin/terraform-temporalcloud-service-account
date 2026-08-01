# Changelog

All notable changes to this project will be documented in this file.

## [2.0.1](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-service-account/compare/v2.0.0...v2.0.1) (2026-08-01)

### Documentation

* Pin the examples to v2 ([d21533f](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-service-account/commit/d21533f844ac3a86f9f9ea5db1db70d70aef5edc))

## [2.0.0](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-service-account/compare/v1.0.4...v2.0.0) (2026-08-01)

### ⚠ BREAKING CHANGES

* name no longer has a default. A module call that sets
create_service_account = false must now pass it explicitly, for example
name = "".

### Features

* Require the inputs the provider requires ([bad9f5f](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-service-account/commit/bad9f5f6a1b8be829ddb2f1a9cdd3b5c000abbc9))

## [1.0.4](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-service-account/compare/v1.0.3...v1.0.4) (2026-08-01)

### Documentation

* Drop the badge explanation from the README ([5a0caa9](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-service-account/commit/5a0caa90e791354bd5644f0af5c4ea573aeb30c1))

## [1.0.3](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-service-account/compare/v1.0.2...v1.0.3) (2026-08-01)

## [1.0.2](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-service-account/compare/v1.0.1...v1.0.2) (2026-08-01)

### Bug Fixes

* Accept the owner and financeadmin account roles ([792bc38](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-service-account/commit/792bc38157360d69edbf54f1c39f3463bec8c981))

## [1.0.1](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-service-account/compare/v1.0.0...v1.0.1) (2026-08-01)

### Bug Fixes

* Return empty values instead of null from optional attribute outputs ([1f0cb27](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-service-account/commit/1f0cb274b20d76ed643f18aa24fdeb314249a735))

## 1.0.0 (2026-08-01)

### Features

* Initial service-account module ([d126c7d](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-service-account/commit/d126c7d434a0c5fc8c389045676443b1451987fd))
