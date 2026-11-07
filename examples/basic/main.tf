terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "bucket" {
  source = "../.."

  project_id         = var.project_id
  name               = "${var.project_id}-example-bucket"
  location           = "US"
  versioning_enabled = true

  # Keep the three newest noncurrent versions of each object and abort
  # multipart uploads that never finished.
  abort_incomplete_multipart_days = 7
  lifecycle_rules = [
    {
      action    = { type = "Delete" }
      condition = { num_newer_versions = 3, with_state = "ARCHIVED" }
    },
  ]

  labels = {
    environment = "sandbox"
  }
}

variable "project_id" {
  description = "Project ID to deploy the example bucket into."
  type        = string
}

variable "region" {
  description = "Region for the google provider."
  type        = string
  default     = "us-central1"
}

output "bucket_url" {
  value = module.bucket.url
}
