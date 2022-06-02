provider "google" {
#   project     = var.gcp_project_id
  region      = var.gcp_region
}

resource "random_string" "random" {
  length           = 4
  special          = false
  upper = false
}

resource "google_project_iam_member" "cepf" {
  project = "cepf-345614"
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:service-${google_project.iap-test.number}@serverless-robot-prod.iam.gserviceaccount.com"
  depends_on = [
    google_project_service.run
  ]
}

resource "google_project" "iap-test" {
  name       = "iap-test"
  project_id = "iap-test-${random_string.random.result}"
  folder_id  = 339514276699
  billing_account = var.billing
}

resource "google_project_service" "project_service" {
  project = google_project.iap-test.project_id
  service = "iap.googleapis.com"
}



resource "google_project_service" "compute" {
  project = google_project.iap-test.project_id
  service = "compute.googleapis.com"
}


# resource "google_project_service" "container" {
#   project = google_project.iap-test.project_id
#   service = "container.googleapis.com"
# }

resource "google_project_service" "vpcaccess" {
  project = google_project.iap-test.project_id
  service = "vpcaccess.googleapis.com"
}

resource "google_project_service" "dns" {
  project = google_project.iap-test.project_id
  service = "dns.googleapis.com"
}




resource "google_compute_network" "vpc_network" {
  name = "default"
  project = google_project.iap-test.project_id
  auto_create_subnetworks = false
  depends_on = [
    google_project_service.compute
  ]
}

resource "google_compute_subnetwork" "subnet" {
  name          = "default"
  ip_cidr_range = "10.2.0.0/16"
  region        = var.gcp_region
  network       = google_compute_network.vpc_network.id
  project = google_project.iap-test.project_id
}

resource "google_iap_brand" "project_brand" {
  support_email     = "admin@liaurora.altostrat.com"
  application_title = "test"
  project = google_project.iap-test.project_id
  depends_on = [
    google_project_service.project_service
  ]
}

resource "google_iap_client" "project_client" {
  display_name = "Test Client"
  brand        =  google_iap_brand.project_brand.name
  }

# enable cloud run api

resource "google_project_service" "run" {
  service = "run.googleapis.com"
  project = google_project.iap-test.project_id
}

resource "google_vpc_access_connector" "connector" {
  name          = "example-vpc-connector"
  region        = var.gcp_region
  project       = google_project.iap-test.project_id
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.vpc_network.name
  depends_on = [
    google_project_service.vpcaccess
  ]
}
