# terraform-google-storage-bucket

Terraform module that manages a [Google Cloud](https://cloud.google.com/)
Cloud Storage bucket (`google_storage_bucket`). It creates a single bucket with
uniform bucket-level access, optional versioning and an optional age-based
lifecycle rule.

Defaults are chosen to be safe rather than permissive: uniform bucket-level
access is on (so legacy per-object ACLs are not a path to public exposure),
public access prevention is `enforced`, and `force_destroy` is off.

## Usage

```hcl
module "bucket" {
  source = "github.com/moveeeax/terraform-google-storage-bucket?ref=v1.0.0"

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
| `public_access_prevention`    | `enforced` or `inherited`.                               | `string`      | `"enforced"` |    no    |
| `kms_key_name`                | Cloud KMS key for CMEK. Null uses Google-managed keys.   | `string`      | `null`       |    no    |
| `versioning_enabled`          | Whether to enable object versioning.                     | `bool`        | `false`      |    no    |
| `force_destroy`               | Whether to delete all objects on destroy.                | `bool`        | `false`      |    no    |
| `lifecycle_age_days`          | Delete objects older than this many days (whole number, `>= 1`). | `number` | `null`   |    no    |
| `labels`                      | Labels applied to the bucket.                            | `map(string)` | `{}`         |    no    |

### Notes

- **`public_access_prevention`** defaults to `"enforced"`, which permanently
  blocks `allUsers` / `allAuthenticatedUsers` grants on the bucket and its
  objects regardless of organization policy. Set it to `"inherited"` only for
  buckets that are deliberately public (for example static website hosting).
- **`lifecycle_age_days`** creates a `Delete` lifecycle rule. It deletes live
  data, so it is validated to be a whole number of days `>= 1` — `age = 0`
  matches every object in the bucket. On a versioned bucket the delete first
  archives the live object; the noncurrent version is removed once it also
  exceeds the age.
- **`kms_key_name`** requires the bucket's service agent to already hold
  `roles/cloudkms.cryptoKeyEncrypterDecrypter` on the key, otherwise bucket
  creation fails. Use `depends_on` on the IAM binding when creating both.

## Outputs

| Name        | Description                     |
|-------------|---------------------------------|
| `id`        | Identifier of the bucket.      |
| `name`      | Name of the bucket.            |
| `url`       | Base gs:// URL of the bucket.  |
| `self_link` | URI of the bucket.             |

## Development

```sh
terraform fmt -recursive
terraform init -backend=false && terraform validate
terraform test    # mocked provider, no credentials or network required
tflint --recursive
```

`terraform test` uses `mock_provider`, which needs Terraform (or OpenTofu)
`>= 1.7`. That is a requirement of the test suite only — the module itself
still supports `>= 1.5`.

## License

[MIT](LICENSE)
