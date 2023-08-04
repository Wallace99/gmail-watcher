variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "location" {
  description = "GCP region."
  type        = string
  default     = "us-central1"
}

variable "image_tag" {
  description = "Cloud Run image tag."
  type        = string
}

variable "force_refresh_creds" {
  description = "Whether to refresh credentials."
  type        = string
  default     = true
}

variable "labels" {
  description = "List of Gmail labels."
  type        = list(string)
}