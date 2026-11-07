# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- `lifecycle_rules` input: a list of lifecycle rules with `Delete`,
  `SetStorageClass` and `AbortIncompleteMultipartUpload` actions and the
  `age`, `num_newer_versions`, `days_since_noncurrent_time`, `with_state`,
  `matches_prefix`, `matches_suffix` and `matches_storage_class` conditions.
  Rules with an empty condition, `age = 0` or `num_newer_versions = 0` are
  rejected because they match every object. `lifecycle_age_days` stays as a
  shortcut.
- `abort_incomplete_multipart_days` input: aborts incomplete multipart uploads
  older than the given number of days.

[Unreleased]: https://github.com/moveeeax/terraform-google-storage-bucket/compare/v1.1.0...HEAD
