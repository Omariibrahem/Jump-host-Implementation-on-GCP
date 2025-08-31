resource "google_compute_network" "vm1-network" {
  name                    = "vm1-network"
  auto_create_subnetworks = false

}
resource "google_compute_subnetwork" "vm1-subnet" {
  name          = "vm1-subnet"
  region        = "us-central1"
  network       = google_compute_network.vm1-network.id
  ip_cidr_range = "10.0.1.0/24"
}

resource "google_compute_network" "vm2-network" {
  name                    = "vm2-network"
  auto_create_subnetworks = false

}

resource "google_compute_subnetwork" "vm2-subnet" {
  name          = "vm2-subnet"
  region        = "us-central1"
  network       = google_compute_network.vm2-network.id
  ip_cidr_range = "10.0.2.0/24"
}