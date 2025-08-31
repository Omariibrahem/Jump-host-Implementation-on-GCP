resource "google_compute_instance" "vm1" {
  name         = "vm1-private"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.vm1-network.id
    subnetwork = google_compute_subnetwork.vm1-subnet.id
    
  }

}

resource "google_compute_instance" "vm2" {
  name         = "vm2-jump-host"
  machine_type = "e2-medium"
  zone         = "us-central1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.vm2-network.id
    subnetwork = google_compute_subnetwork.vm2-subnet.id
   access_config {
     
   }
  }
}
