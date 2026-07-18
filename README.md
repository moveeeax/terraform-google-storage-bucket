# terraform-google-storage-bucket

Terraform module that manages a [Google Cloud](https://cloud.google.com/)
Cloud Storage bucket (`google_storage_bucket`). It creates a single bucket with
uniform bucket-level access, optional versioning and an optional age-based
lifecycle rule.

## Usage

```hcl
module "bucket" {
  source = "github.com/cybercapybara/terraform-google-storage-bucket"

  project_id         = var.project_id
  name               = "my-app-assets"
  location           = "US"
  versioning_enabled = true
  lifecycle_age_days = 90
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| google    | >= 5.0   |

## Inputs

| Name                          | Description                                              | Type          | Default      | Required |
|-------------------------------|----------------------------------------------------------|---------------|--------------|:--------:|
| `project_id`                  | ID of the project in which to create the bucket.         | `string`      | n/a          |   yes    |
| `name`                        | Globally unique name of the bucket.                      | `string`      | n/a          |   yes    |
| `location`                    | Location of the bucket.                                  | `string`      | `"US"`       |    no    |
| `storage_class`               | Storage class of the bucket.                             | `string`      | `"STANDARD"` |    no    |
| `uniform_bucket_level_access` | Whether to enable uniform bucket-level access.           | `bool`        | `true`       |    no    |
| `versioning_enabled`          | Whether to enable object versioning.                     | `bool`        | `false`      |    no    |
| `force_destroy`               | Whether to delete all objects on destroy.                | `bool`        | `false`      |    no    |
| `lifecycle_age_days`          | Delete objects older than this many days.                | `number`      | `null`       |    no    |
| `labels`                      | Labels applied to the bucket.                            | `map(string)` | `{}`         |    no    |

## Outputs

| Name        | Description                     |
|-------------|---------------------------------|
| `id`        | Identifier of the bucket.      |
| `name`      | Name of the bucket.            |
| `url`       | Base gs:// URL of the bucket.  |
| `self_link` | URI of the bucket.             |

## License

[MIT](LICENSE)
