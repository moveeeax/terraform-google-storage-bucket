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

variable "labels" {
  description = "Labels applied to the bucket."
  type        = map(string)
  default     = {}
}
