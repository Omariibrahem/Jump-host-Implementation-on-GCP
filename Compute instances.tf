resource "google_compute_instance" "vm1" {
  name         = var.private_instance_name
  machine_type = var.private_instance_type
  zone         = var.availability_zone_private

  boot_disk {
    initialize_params {
      image = var.private_instance_ami
    }
  }

  network_interface {
    network    = google_compute_network.vm1-network.id
    subnetwork = google_compute_subnetwork.vm1-subnet.id
  }

  tags = [var.environment]
}

resource "google_compute_instance" "vm2" {
  name         = var.public_instance_name
  machine_type = var.public_instance_type
  zone         = var.availability_zone_public

  boot_disk {
    initialize_params {
      image = var.public_instance_ami
    }
  }

  network_interface {
    network    = google_compute_network.vm2-network.id
    subnetwork = google_compute_subnetwork.vm2-subnet.id
    access_config {}
  }

  tags = [var.environment]
}