# This bucket is shared across all environments to store packaged artifacts.
# It is deployed independently of any specific environment.
resource "aws_s3_bucket" "package_registry" {
  bucket = "sally-package-registry"
}