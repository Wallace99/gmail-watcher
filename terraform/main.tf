locals {
  topic_map_string = join(",", [for t in google_pubsub_topic.label_topics : "${t.name},${t.id}"])
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
  project = var.project_id
  location = google_cloud_run_v2_job.gmail_watcher.location
  name = google_cloud_run_v2_job.gmail_watcher.name
  role = "roles/run.invoker"
  member = "serviceAccount:${google_service_account.cloud_run_scheduler.email}"
}

resource "google_project_iam_member" "datastore_user" {
  project = var.project_id
  member = "serviceAccount:${google_service_account.cloud_run_sa.email}"
  role = "roles/datastore.user"
}

resource "google_cloud_run_v2_job" "gmail_watcher" {
  name     = "gmail-watcher"
  location = "us-central1"

  template {
    template {
      service_account = google_service_account.cloud_run_sa.email

      containers {
        image = "${var.location}-docker.pkg.dev/${var.project_id}/artifact-registry/gmail-watcher:${var.image_tag}"

        env {
          name  = "force_refresh"
          value = var.force_refresh_creds
        }

        env {
          name  = "labels_to_watch"
          value = local.topic_map_string
        }
      }
    }
  }
}

resource "google_pubsub_topic" "label_topics" {
  for_each = toset(var.labels)
  name     = replace(lower(each.value), " ", "_")
  project  = var.project_id

  message_retention_duration = "86600s"
}

resource "google_pubsub_topic_iam_member" "gmail_member" {
  for_each = google_pubsub_topic.label_topics

  project = var.project_id
  topic = each.value.id
  role = "roles/pubsub.publisher"
  member = "serviceAccount:gmail-api-push@system.gserviceaccount.com"
}

resource "google_cloud_scheduler_job" "trigger_job" {
  name             = "schedule-gmail-watcher"
  schedule         = "0 9 * * 1"
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