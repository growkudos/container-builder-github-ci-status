// Save tf state in bucket
terraform {
  backend "gcs" {
    bucket = "growkudos-com-terraform-state"
    prefix  = "gcp/functions/setCIStatus"
    region = "europe-west2-a"
  }
}

provider "google" {
  project = "${var.project}"
  region   = "europe-west-2a"
}

data "archive_file" "setCIStatus" {
  type        = "zip"
  output_path = "setCIStatus.zip"
  source {
    content = "${file("../index.js")}"
    filename = "index.js"
  }
  source {
    content = "${file("../package.json")}"
    filename = "package.json"
  }
}

resource "google_storage_bucket" "bucket" {
  name = "growkudos-com-gcp-functions"
  location = "US" # match the function region
}

resource "google_storage_bucket_object" "archive" {
  name   = "${data.archive_file.setCIStatus.output_md5}.${data.archive_file.setCIStatus.output_path}"
  bucket = "${google_storage_bucket.bucket.name}"
  source = "${data.archive_file.setCIStatus.output_path}"
}

resource "google_cloudfunctions_function" "function" {
  name                  = "setCIStatus"
  description           = "Managed by Terraform"
  region                = "us-central1"
  runtime               = "nodejs8"
  entry_point            = "setCIStatus"
  event_trigger = {
    event_type = "providers/cloud.pubsub/eventTypes/topic.publish"
    resource = "cloud-builds"
  }
  source_archive_bucket = "${google_storage_bucket.bucket.name}"
  source_archive_object = "${google_storage_bucket_object.archive.name}"
  labels = {
    deployment-tool = "cli-gcloud"
  }
  environment_variables = {
    GITHUB_TOKEN = "${var.github_token}"
  }
}
