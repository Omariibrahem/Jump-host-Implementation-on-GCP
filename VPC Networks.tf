resource "google_compute_network" "vm1-network" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vm1-subnet" {
  name          = var.public_subnet_name
  region        = var.region
  network       = google_compute_network.vm1-network.id
  ip_cidr_range = var.public_subnet_cidr
}

resource "google_compute_network" "vm2-network" {
  name                    = var.vpc_name_private
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vm2-subnet" {
  name          = var.private_subnet_name
  region        = var.region
  network       = google_compute_network.vm2-network.id
  ip_cidr_range = var.private_subnet_cidr
}