output "ip" {
  value       = google_compute_address.relay.address
  description = "Static external IP of gcp-relay"
}

output "instance_self_link" {
  value       = google_compute_instance.relay.self_link
  description = "Self-link of the gcp-relay instance"
}
