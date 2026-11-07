variable "project_id" {
  description = "ID of the project in which to create the bucket."
  type        = string
}

variable "name" {
  description = "Globally unique name of the storage bucket."
  type        = string
}

variable "location" {
  description = "Location of the bucket, e.g. US, EU or us-central1."
  type        = string
  default     = "US"
}

variable "storage_class" {
  description = "Storage class of the bucket."
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "storage_class must be one of STANDARD, NEARLINE, COLDLINE or ARCHIVE."
  }
}

variable "uniform_bucket_level_access" {
  description = "Whether to enable uniform bucket-level access (recommended)."
  type        = bool
  default     = true
}

variable "public_access_prevention" {
  description = <<-EOT
    Public access prevention for the bucket. "enforced" (the default) blocks the
    bucket and its objects from ever being granted to allUsers/allAuthenticatedUsers.
    "inherited" defers to the organization policy, which leaves public exposure
    possible. Only set "inherited" for buckets that are deliberately public.
  EOT
  type        = string
  default     = "enforced"

  validation {
    condition     = contains(["enforced", "inherited"], var.public_access_prevention)
    error_message = "public_access_prevention must be either \"enforced\" or \"inherited\"."
  }
}

variable "kms_key_name" {
  description = <<-EOT
    Self link of a Cloud KMS key to use for customer-managed encryption (CMEK),
    e.g. projects/p/locations/us/keyRings/r/cryptoKeys/k. Null uses Google-managed
    encryption keys. The bucket's service agent must hold roles/cloudkms.cryptoKeyEncrypterDecrypter
    on the key before the bucket is created.
  EOT
  type        = string
  default     = null
}

variable "versioning_enabled" {
  description = "Whether to enable object versioning."
  type        = bool
  default     = false
}

variable "force_destroy" {
  description = "Whether to delete all objects when the bucket is destroyed."
  type        = bool
  default     = false
}

variable "lifecycle_age_days" {
  description = "Delete objects older than this many days. Null disables the lifecycle rule."
  type        = number
  default     = null

  validation {
    # `age = 0` matches every object in the bucket and would delete live data on
    # the next lifecycle sweep, so require an explicit whole number of days >= 1.
    condition     = var.lifecycle_age_days == null || try(var.lifecycle_age_days >= 1 && floor(var.lifecycle_age_days) == var.lifecycle_age_days, false)
    error_message = "lifecycle_age_days must be null or a whole number of days >= 1; 0 or a negative value would delete live objects immediately."
  }
}

variable "lifecycle_rules" {
  description = <<-EOT
    Additional lifecycle rules, applied after the lifecycle_age_days and
    abort_incomplete_multipart_days shortcuts. action.type is Delete,
    SetStorageClass (requires action.storage_class) or AbortIncompleteMultipartUpload.
    Every condition field is optional, but each rule must set at least one.
  EOT
  type = list(object({
    action = object({
      type          = string
      storage_class = optional(string)
    })
    condition = object({
      age                        = optional(number)
      num_newer_versions         = optional(number)
      days_since_noncurrent_time = optional(number)
      with_state                 = optional(string)
      matches_prefix             = optional(list(string))
      matches_suffix             = optional(list(string))
      matches_storage_class      = optional(list(string))
    })
  }))
  default = []

  validation {
    condition     = alltrue([for r in var.lifecycle_rules : contains(["Delete", "SetStorageClass", "AbortIncompleteMultipartUpload"], r.action.type)])
    error_message = "lifecycle_rules[*].action.type must be Delete, SetStorageClass or AbortIncompleteMultipartUpload."
  }

  validation {
    condition = alltrue([
      for r in var.lifecycle_rules : r.action.type == "SetStorageClass"
      ? try(contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], r.action.storage_class), false)
      : r.action.storage_class == null
    ])
    error_message = "lifecycle_rules[*].action.storage_class is required for SetStorageClass (STANDARD, NEARLINE, COLDLINE or ARCHIVE) and must be null for other action types."
  }

  validation {
    # An empty condition matches every object, so a Delete rule without one
    # would wipe the bucket on the next lifecycle sweep.
    condition     = alltrue([for r in var.lifecycle_rules : anytrue([for v in values(r.condition) : v != null])])
    error_message = "Each lifecycle_rules entry must set at least one condition field; an empty condition matches every object."
  }

  validation {
    # Same reasoning as lifecycle_age_days: age = 0 matches every object.
    condition = alltrue([
      for r in var.lifecycle_rules : r.condition.age == null || try(r.condition.age >= 1 && floor(r.condition.age) == r.condition.age, false)
    ])
    error_message = "lifecycle_rules[*].condition.age must be null or a whole number of days >= 1."
  }

  validation {
    condition = alltrue(flatten([
      for r in var.lifecycle_rules : [
        r.condition.num_newer_versions == null || try(r.condition.num_newer_versions >= 1 && floor(r.condition.num_newer_versions) == r.condition.num_newer_versions, false),
        r.condition.days_since_noncurrent_time == null || try(r.condition.days_since_noncurrent_time >= 0 && floor(r.condition.days_since_noncurrent_time) == r.condition.days_since_noncurrent_time, false),
      ]
    ]))
    error_message = "lifecycle_rules[*].condition.num_newer_versions must be a whole number >= 1 and days_since_noncurrent_time a whole number >= 0."
  }

  validation {
    condition     = alltrue([for r in var.lifecycle_rules : r.condition.with_state == null || contains(["LIVE", "ARCHIVED", "ANY"], coalesce(r.condition.with_state, "-"))])
    error_message = "lifecycle_rules[*].condition.with_state must be LIVE, ARCHIVED or ANY."
  }
}

variable "abort_incomplete_multipart_days" {
  description = "Abort incomplete multipart uploads older than this many days. Null disables the rule."
  type        = number
  default     = null

  validation {
    condition     = var.abort_incomplete_multipart_days == null || try(var.abort_incomplete_multipart_days >= 1 && floor(var.abort_incomplete_multipart_days) == var.abort_incomplete_multipart_days, false)
    error_message = "abort_incomplete_multipart_days must be null or a whole number of days >= 1."
  }
}

variable "labels" {
  description = "Labels applied to the bucket."
  type        = map(string)
  default     = {}
}
