terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  backend "gcs" {
    bucket = "gcp-relay-nixos-images"
    prefix = "tofu/state"
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

import {
  id = "projects/homelab-497717/regions/us-central1/addresses/gcp-relay-ip"
  to = google_compute_address.relay
}

import {
  id = "gcp-relay-nixos-images"
  to = google_storage_bucket.images
}

import {
  id = "projects/homelab-497717/global/images/gcp-relay-20260601"
  to = google_compute_image.nixos
}

import {
  id = "projects/homelab-497717/zones/us-central1-a/instances/gcp-relay"
  to = google_compute_instance.relay
}

# Static IP
resource "google_compute_address" "relay" {
  name         = "gcp-relay-ip"
  region       = var.region
  network_tier = "STANDARD"
}

# GCS bucket for NixOS images
resource "google_storage_bucket" "images" {
  name                        = "gcp-relay-nixos-images"
  location                    = "US-CENTRAL1"
  force_destroy               = true
  uniform_bucket_level_access = false

  lifecycle_rule {
    condition { age = 7 }
    action { type = "Delete" }
  }
}

# NixOS image (updated via nixos-rebuild / nh os build-image)
resource "google_compute_image" "nixos" {
  name   = "gcp-relay-${var.image_date}"
  family = "nixos-gcp-relay"

  raw_disk {
    source = "https://storage.googleapis.com/${google_storage_bucket.images.name}/nixos-gcp-relay-v${var.image_date}.raw.tar.gz"
  }

  provisioner "local-exec" {
    command = "gsutil rm gs://${google_storage_bucket.images.name}/nixos-gcp-relay-v${var.image_date}.raw.tar.gz || true"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [raw_disk]
  }
}

# Firewall: HTTP/HTTPS
resource "google_compute_firewall" "http_https" {
  name    = "gcp-relay-allow-http-https"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server", "https-server"]
}

# Firewall: DERP/STUN (headscale)
resource "google_compute_firewall" "derp" {
  name    = "gcp-relay-allow-derp"
  network = "default"

  allow {
    protocol = "udp"
    ports    = ["3478"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server", "https-server"]
}

# VM instance
resource "google_compute_instance" "relay" {
  name         = "gcp-relay"
  machine_type = "e2-micro"
  zone         = var.zone

  tags = ["http-server", "https-server"]

  boot_disk {
    initialize_params {
      image = google_compute_image.nixos.self_link
      size  = 30
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip       = google_compute_address.relay.address
      network_tier = "STANDARD"
    }
  }

  metadata = {
    enable-oslogin     = "FALSE"
    serial-port-enable = "TRUE"
  }

  lifecycle {
    replace_triggered_by = [google_compute_image.nixos]
    ignore_changes       = [service_account]
  }
}
