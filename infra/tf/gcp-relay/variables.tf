variable "project" {
  type        = string
  description = "GCP project ID"
  default     = "homelab-497717"
}

variable "region" {
  type        = string
  description = "GCP region"
  default     = "us-central1"
}

variable "zone" {
  type        = string
  description = "GCP zone"
  default     = "us-central1-a"
}

variable "image_date" {
  type        = string
  description = "Date suffix for the NixOS image (YYYYMMDD), matches the GCS object name"
}
