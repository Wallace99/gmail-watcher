locals {
  topic_map_string = join(",", [for t in google_pubsub_topic.label_topics : "${t.name},${t.id}"])
}

resource "google_service_account" "cloud_run_sa" {
  account_id = "gmail-watcher"
  project    = var.project_id
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