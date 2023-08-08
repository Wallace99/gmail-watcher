locals {
  bucket_map_string = join(",", [for t in var.label_config : "${t.label_id},${t.bucket_name}"])
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_service_account" "cloud_run_sa" {
  account_id = "gmail-watcher"
  project    = var.project_id
}

resource "google_service_account" "cloud_run_scheduler" {
  account_id = "scheduler"
  project    = var.project_id
}

resource "google_cloud_run_v2_job_iam_member" "cloud_run_invoker_member" {
  project  = var.project_id
  location = google_cloud_run_v2_job.gmail_watcher.location
  name     = google_cloud_run_v2_job.gmail_watcher.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.cloud_run_scheduler.email}"
}

resource "google_project_iam_member" "datastore_user" {
  project = var.project_id
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
  role    = "roles/datastore.user"
}

resource "google_cloud_run_v2_job" "gmail_watcher" {
  name     = "gmail-watcher"
  location = "us-central1"

  template {
    template {
      service_account = google_service_account.cloud_run_sa.email
      max_retries     = 1

      containers {
        image = "${var.location}-docker.pkg.dev/${var.project_id}/artifact-registry/gmail-watcher:${var.image_tag}"

        env {
          name  = "force_refresh"
          value = var.force_refresh_creds
        }

        env {
          name  = "labels_to_process"
          value = local.bucket_map_string
        }
      }
    }
  }
}

resource "google_storage_bucket" "file_bucket" {
  for_each      = { for item in var.label_config : item.label_id => item }
  name          = each.value.bucket_name
  location      = var.location
  force_destroy = true
  project       = var.project_id

  public_access_prevention = "enforced"
}

resource "google_storage_bucket_iam_member" "storage_member" {
  for_each = google_storage_bucket.file_bucket
  bucket   = google_storage_bucket.file_bucket[each.key].id
  role     = "roles/storage.admin"
  member   = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_cloud_scheduler_job" "trigger_job" {
  name             = "schedule-gmail-watcher"
  schedule         = "0 8 * * *"
  attempt_deadline = "320s"
  region           = var.location
  project          = var.project_id

  retry_config {
    retry_count = 3
  }

  http_target {
    http_method = "POST"
    uri         = "https://${google_cloud_run_v2_job.gmail_watcher.location}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${data.google_project.project.number}/jobs/${google_cloud_run_v2_job.gmail_watcher.name}:run"

    oauth_token {
      service_account_email = google_service_account.cloud_run_scheduler.email
    }
  }
}