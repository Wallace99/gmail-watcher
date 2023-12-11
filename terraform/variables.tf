variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "location" {
  description = "GCP region."
  type        = string
  default     = "australia-southeast1"
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


variable "label_config" {
  description = "Configuration for Gmail labels."
  type = list(object({
    name         = string
    label_id     = string
    bucket_name  = string
    days_to_keep = number # 0 means forever
  }))
}