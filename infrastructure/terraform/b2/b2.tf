resource "b2_bucket" "cbc02009-volsync-backup" {
  bucket_name = "cbc02009-volsync-backup"
  bucket_type = "allPrivate"
}

module "onepassword_item_b2" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Services"
  item   = "b2"
}

resource "b2_application_key" "restic-key" {
  key_name     = "restic-key"
  capabilities = [
    "deleteFiles",
    "listAllBucketNames",
    "listBuckets",
    "listFiles",
    "readBuckets",
    "readFiles",
    "shareFiles",
    "writeFiles"
  ]
}
