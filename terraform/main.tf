resource "google_cloud_run_v2_job" "mail_watcher" {
  name     = "mail-watcher"
  location = "us-central1"

  template {
    template {
      containers {
        image = "us-docker.pkg.dev/cloudrun/container/hello"
      }
    }
  }
}