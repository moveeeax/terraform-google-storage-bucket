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
}

variable "labels" {
  description = "Labels applied to the bucket."
  type        = map(string)
  default     = {}
}
