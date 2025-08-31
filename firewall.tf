resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vm1-network.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

source_ranges = ["10.0.2.0/24", "35.235.240.0/20"]
}

resource "google_compute_firewall" "allow_ssh_vm2" {
  name    = "allow-ssh-vm2"
  network = google_compute_network.vm2-network.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}
