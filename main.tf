locals {
  public_principals = ["allUsers", "allAuthenticatedUsers"]

  # role -> [members] flattened to one entry per binding, keyed "<role> <member>".
  iam_members = {
    for binding in flatten([
      for role, members in var.iam_members : [
        for member in distinct(members) : { role = role, member = member }
      ]
    ]) : "${binding.role} ${binding.member}" => binding
  }
}

resource "google_storage_bucket" "this" {
  project                     = var.project_id
  name                        = var.name
  location                    = var.location
  storage_class               = var.storage_class
  uniform_bucket_level_access = var.uniform_bucket_level_access
  public_access_prevention    = var.public_access_prevention
  force_destroy               = var.force_destroy
  labels                      = var.labels

  versioning {
    enabled = var.versioning_enabled
  }

  dynamic "encryption" {
    for_each = var.kms_key_name == null ? [] : [var.kms_key_name]
    content {
      default_kms_key_name = encryption.value
    }
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_age_days == null ? [] : [var.lifecycle_age_days]
    content {
      action {
        type = "Delete"
      }
      condition {
        age = lifecycle_rule.value
      }
    }
  }

  dynamic "lifecycle_rule" {
    for_each = var.abort_incomplete_multipart_days == null ? [] : [var.abort_incomplete_multipart_days]
    content {
      action {
        type = "AbortIncompleteMultipartUpload"
      }
      condition {
        age = lifecycle_rule.value
      }
    }
  }

  # Rendered after the two shortcut rules above so callers that only use the
  # shortcuts keep the same rule order in their plans.
  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = lifecycle_rule.value.action.storage_class
      }
      condition {
        age                        = lifecycle_rule.value.condition.age
        num_newer_versions         = lifecycle_rule.value.condition.num_newer_versions
        days_since_noncurrent_time = lifecycle_rule.value.condition.days_since_noncurrent_time
        with_state                 = lifecycle_rule.value.condition.with_state
        matches_prefix             = lifecycle_rule.value.condition.matches_prefix
        matches_suffix             = lifecycle_rule.value.condition.matches_suffix
        matches_storage_class      = lifecycle_rule.value.condition.matches_storage_class
      }
    }
  }
}

resource "google_storage_bucket_iam_member" "this" {
  for_each = local.iam_members

  bucket = google_storage_bucket.this.name
  role   = each.value.role
  member = each.value.member

  lifecycle {
    precondition {
      # Public principals need two explicit opt-ins: allow_public here, and
      # public_access_prevention = "inherited" on the bucket, since "enforced"
      # makes the API reject the grant anyway.
      condition     = !contains(local.public_principals, each.value.member) || (var.allow_public && var.public_access_prevention == "inherited")
      error_message = "${each.value.member} makes the bucket public. Set allow_public = true and public_access_prevention = \"inherited\" if that is intended."
    }
  }
}
