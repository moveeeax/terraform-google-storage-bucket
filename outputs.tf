output "id" {
  description = "Identifier of the bucket."
  value       = google_storage_bucket.this.id
}

output "name" {
  description = "Name of the bucket."
  value       = google_storage_bucket.this.name
}

output "url" {
  description = "Base gs:// URL of the bucket."
  value       = google_storage_bucket.this.url
}

output "self_link" {
  description = "URI of the bucket."
  value       = google_storage_bucket.this.self_link
}
