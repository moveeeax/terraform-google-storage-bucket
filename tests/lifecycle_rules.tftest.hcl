# Test-only requirement: `mock_provider` needs Terraform >= 1.7 (OpenTofu >= 1.7).
mock_provider "google" {}

variables {
  project_id = "example-project"
  name       = "example-bucket"
}

run "noncurrent_cleanup_and_tiering" {
  variables {
    versioning_enabled = true
    lifecycle_rules = [
      {
        action    = { type = "SetStorageClass", storage_class = "NEARLINE" }
        condition = { age = 30, matches_storage_class = ["STANDARD"] }
      },
      {
        action    = { type = "Delete" }
        condition = { num_newer_versions = 3, with_state = "ARCHIVED" }
      },
      {
        action    = { type = "Delete" }
        condition = { days_since_noncurrent_time = 7, matches_prefix = ["tmp/"], matches_suffix = [".log"] }
      },
    ]
  }

  assert {
    condition     = length(google_storage_bucket.this.lifecycle_rule) == 3
    error_message = "Every entry in lifecycle_rules must become one lifecycle_rule block."
  }

  assert {
    condition     = one(google_storage_bucket.this.lifecycle_rule[0].action).type == "SetStorageClass" && one(google_storage_bucket.this.lifecycle_rule[0].action).storage_class == "NEARLINE"
    error_message = "A SetStorageClass rule must carry its target storage class."
  }

  assert {
    condition     = one(google_storage_bucket.this.lifecycle_rule[0].condition).age == 30 && one(google_storage_bucket.this.lifecycle_rule[0].condition).matches_storage_class == tolist(["STANDARD"])
    error_message = "The tiering rule must keep its age and matches_storage_class conditions."
  }

  assert {
    condition     = one(google_storage_bucket.this.lifecycle_rule[1].condition).num_newer_versions == 3 && one(google_storage_bucket.this.lifecycle_rule[1].condition).with_state == "ARCHIVED"
    error_message = "The noncurrent cleanup rule must keep num_newer_versions and with_state."
  }

  assert {
    condition     = one(google_storage_bucket.this.lifecycle_rule[2].condition).days_since_noncurrent_time == 7 && one(google_storage_bucket.this.lifecycle_rule[2].condition).matches_prefix == tolist(["tmp/"]) && one(google_storage_bucket.this.lifecycle_rule[2].condition).matches_suffix == tolist([".log"])
    error_message = "The prefix/suffix rule must keep days_since_noncurrent_time, matches_prefix and matches_suffix."
  }
}

run "shortcuts_come_before_the_list" {
  variables {
    lifecycle_age_days              = 365
    abort_incomplete_multipart_days = 2
    lifecycle_rules = [
      {
        action    = { type = "SetStorageClass", storage_class = "COLDLINE" }
        condition = { age = 90 }
      },
    ]
  }

  assert {
    condition     = length(google_storage_bucket.this.lifecycle_rule) == 3
    error_message = "lifecycle_age_days, abort_incomplete_multipart_days and lifecycle_rules must all be rendered."
  }

  assert {
    condition     = one(google_storage_bucket.this.lifecycle_rule[0].action).type == "Delete" && one(google_storage_bucket.this.lifecycle_rule[0].condition).age == 365
    error_message = "The lifecycle_age_days shortcut must stay the first rule so existing plans do not reorder."
  }

  assert {
    condition     = one(google_storage_bucket.this.lifecycle_rule[1].action).type == "AbortIncompleteMultipartUpload" && one(google_storage_bucket.this.lifecycle_rule[1].condition).age == 2
    error_message = "abort_incomplete_multipart_days must create an AbortIncompleteMultipartUpload rule with the requested age."
  }

  assert {
    condition     = one(google_storage_bucket.this.lifecycle_rule[2].action).storage_class == "COLDLINE"
    error_message = "lifecycle_rules entries must follow the shortcut rules."
  }
}

run "rejects_unknown_action_type" {
  command = plan

  variables {
    lifecycle_rules = [{ action = { type = "Archive" }, condition = { age = 30 } }]
  }

  expect_failures = [var.lifecycle_rules]
}

run "rejects_set_storage_class_without_a_class" {
  command = plan

  variables {
    lifecycle_rules = [{ action = { type = "SetStorageClass" }, condition = { age = 30 } }]
  }

  expect_failures = [var.lifecycle_rules]
}

run "rejects_storage_class_on_a_delete_rule" {
  command = plan

  variables {
    lifecycle_rules = [{ action = { type = "Delete", storage_class = "COLDLINE" }, condition = { age = 30 } }]
  }

  expect_failures = [var.lifecycle_rules]
}

run "rejects_rule_with_an_empty_condition" {
  command = plan

  variables {
    lifecycle_rules = [{ action = { type = "Delete" }, condition = {} }]
  }

  expect_failures = [var.lifecycle_rules]
}

run "rejects_rule_age_of_zero_days" {
  command = plan

  variables {
    lifecycle_rules = [{ action = { type = "Delete" }, condition = { age = 0 } }]
  }

  expect_failures = [var.lifecycle_rules]
}

run "rejects_zero_num_newer_versions" {
  command = plan

  variables {
    lifecycle_rules = [{ action = { type = "Delete" }, condition = { num_newer_versions = 0 } }]
  }

  expect_failures = [var.lifecycle_rules]
}

run "rejects_unknown_with_state" {
  command = plan

  variables {
    lifecycle_rules = [{ action = { type = "Delete" }, condition = { age = 30, with_state = "NONCURRENT" } }]
  }

  expect_failures = [var.lifecycle_rules]
}

run "rejects_abort_multipart_of_zero_days" {
  command = plan

  variables {
    abort_incomplete_multipart_days = 0
  }

  expect_failures = [var.abort_incomplete_multipart_days]
}
