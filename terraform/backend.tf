terraform {
  backend "gcs" {
    bucket  = "tf-state-wallace-mail"
    prefix  = "terraform/state"
  }
}