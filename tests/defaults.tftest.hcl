# Test-only requirement: `mock_provider` needs Terraform >= 1.7 (OpenTofu >= 1.7).
# The module itself still supports >= 1.5 — do not raise required_version for this.
mock_provider "google" {}

variables {
  project_id = "example-project"
  name       = "example-bucket"
}

run "defaults_are_safe" {
  assert {
    condition     = google_storage_bucket.this.uniform_bucket_level_access == true
    error_message = "Uniform bucket-level access must default to true; otherwise legacy per-object ACLs stay a live path to public exposure."
  }

  assert {
    condition     = google_storage_bucket.this.public_access_prevention == "enforced"
    error_message = "public_access_prevention must default to \"enforced\" so the bucket cannot be granted to allUsers."
  }

  assert {
    condition     = google_storage_bucket.this.force_destroy == false
    error_message = "force_destroy must default to false so a destroy cannot silently delete objects."
  }

  assert {
    condition     = google_storage_bucket.this.storage_class == "STANDARD"
    error_message = "storage_class must default to STANDARD."
  }

  assert {
    condition     = length(google_storage_bucket.this.lifecycle_rule) == 0
    error_message = "No lifecycle rule may be created when lifecycle_age_days is null."
  }

  assert {
    condition     = length(google_storage_bucket.this.encryption) == 0
    error_message = "No CMEK encryption block may be created when kms_key_name is null."
  }
}

run "versioning_can_be_enabled" {
  variables {
    versioning_enabled = true
  }

  assert {
    condition     = google_storage_bucket.this.versioning[0].enabled == true
    error_message = "versioning_enabled = true must enable object versioning on the bucket."
  }
}

run "lifecycle_rule_deletes_on_the_requested_age" {
  variables {
    lifecycle_age_days = 30
  }

  assert {
    condition     = length(google_storage_bucket.this.lifecycle_rule) == 1
    error_message = "Exactly one lifecycle rule must be created when lifecycle_age_days is set."
  }

  assert {
    condition     = one(google_storage_bucket.this.lifecycle_rule[0].action).type == "Delete"
    error_message = "The lifecycle rule action must be Delete."
  }

  assert {
    condition     = one(google_storage_bucket.this.lifecycle_rule[0].condition).age == 30
    error_message = "The lifecycle rule must match the requested age, not some other condition."
  }
}

run "cmek_key_is_wired_through" {
  variables {
    kms_key_name = "projects/example-project/locations/us/keyRings/example/cryptoKeys/bucket"
  }

  assert {
    condition     = google_storage_bucket.this.encryption[0].default_kms_key_name == "projects/example-project/locations/us/keyRings/example/cryptoKeys/bucket"
    error_message = "kms_key_name must be passed through as the bucket's default KMS key."
  }
}

run "public_bucket_requires_an_explicit_opt_out" {
  command = plan

  variables {
    public_access_prevention = "disabled"
  }

  expect_failures = [var.public_access_prevention]
}

run "rejects_invalid_storage_class" {
  command = plan

  variables {
    storage_class = "GLACIER"
  }

  expect_failures = [var.storage_class]
}

run "rejects_lifecycle_age_of_zero_days" {
  command = plan

  variables {
    lifecycle_age_days = 0
  }

  expect_failures = [var.lifecycle_age_days]
}

run "rejects_negative_lifecycle_age" {
  command = plan

  variables {
    lifecycle_age_days = -1
  }

  expect_failures = [var.lifecycle_age_days]
}

run "rejects_fractional_lifecycle_age" {
  command = plan

  variables {
    lifecycle_age_days = 1.5
  }

  expect_failures = [var.lifecycle_age_days]
}
