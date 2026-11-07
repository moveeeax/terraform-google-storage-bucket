# Test-only requirement: `mock_provider` needs Terraform >= 1.7 (OpenTofu >= 1.7).
mock_provider "google" {}

variables {
  project_id = "example-project"
  name       = "example-bucket"
}

run "no_iam_by_default" {
  command = plan

  assert {
    condition     = length(google_storage_bucket_iam_member.this) == 0
    error_message = "No bucket IAM members may be created when iam_members is empty."
  }
}

run "grants_each_role_member_pair" {
  command = plan

  variables {
    iam_members = {
      "roles/storage.objectViewer" = [
        "serviceAccount:reader@example-project.iam.gserviceaccount.com",
        "group:readers@example.com",
      ]
      "roles/storage.objectCreator" = ["serviceAccount:writer@example-project.iam.gserviceaccount.com"]
    }
  }

  assert {
    condition     = length(google_storage_bucket_iam_member.this) == 3
    error_message = "Every role/member pair must become one google_storage_bucket_iam_member."
  }

  assert {
    condition     = google_storage_bucket_iam_member.this["roles/storage.objectCreator serviceAccount:writer@example-project.iam.gserviceaccount.com"].role == "roles/storage.objectCreator"
    error_message = "The binding must carry the role from the iam_members key."
  }

  assert {
    condition     = google_storage_bucket_iam_member.this["roles/storage.objectViewer group:readers@example.com"].member == "group:readers@example.com"
    error_message = "The binding must carry the member from the iam_members list."
  }

  assert {
    condition     = alltrue([for b in google_storage_bucket_iam_member.this : b.bucket == "example-bucket"])
    error_message = "Every binding must target the module's bucket."
  }
}

run "duplicate_members_are_granted_once" {
  command = plan

  variables {
    iam_members = {
      "roles/storage.objectViewer" = ["group:readers@example.com", "group:readers@example.com"]
    }
  }

  assert {
    condition     = length(google_storage_bucket_iam_member.this) == 1
    error_message = "A member listed twice under the same role must be granted once."
  }
}

run "public_member_is_rejected_by_default" {
  command = plan

  variables {
    iam_members = {
      "roles/storage.objectViewer" = ["allUsers"]
    }
  }

  expect_failures = [google_storage_bucket_iam_member.this]
}

run "public_member_needs_inherited_prevention_too" {
  command = plan

  variables {
    allow_public = true
    iam_members = {
      "roles/storage.objectViewer" = ["allAuthenticatedUsers"]
    }
  }

  expect_failures = [google_storage_bucket_iam_member.this]
}

run "public_member_with_both_opt_ins" {
  command = plan

  variables {
    allow_public             = true
    public_access_prevention = "inherited"
    iam_members = {
      "roles/storage.objectViewer" = ["allUsers"]
    }
  }

  assert {
    condition     = google_storage_bucket_iam_member.this["roles/storage.objectViewer allUsers"].member == "allUsers"
    error_message = "allUsers must be granted when allow_public = true and public_access_prevention = \"inherited\"."
  }
}

run "rejects_a_role_without_a_roles_prefix" {
  command = plan

  variables {
    iam_members = {
      "storage.objectViewer" = ["group:readers@example.com"]
    }
  }

  expect_failures = [var.iam_members]
}

run "rejects_an_empty_member" {
  command = plan

  variables {
    iam_members = {
      "roles/storage.objectViewer" = [""]
    }
  }

  expect_failures = [var.iam_members]
}
