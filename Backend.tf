terraform {
  backend "gcs" {
    bucket  = "your-terraform-state-bucket_konnecta"
    prefix  = "state"
  }
}