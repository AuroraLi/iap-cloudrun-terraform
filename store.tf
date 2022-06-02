
resource "google_cloud_run_service" "frontend-svc" {
  name     = "frontend-svc"
  location = var.gcp_region
  project = google_project.iap-test.project_id
  
  metadata {
    annotations = {
      "run.googleapis.com/ingress" : "internal-and-cloud-load-balancing"
    }
  }
  template {
    metadata {
      annotations = {
        "run.googleapis.com/vpc-access-connector" : google_vpc_access_connector.connector.name
      }
    }
    spec {
      containers {
        image = var.frontend_app_image
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

    depends_on = [google_project_service.run, google_project_iam_member.cepf]
}


resource "google_compute_region_network_endpoint_group" "frontend_neg" {
  provider              = google
  name                  = "frontend-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.gcp_region
  project = google_project.iap-test.project_id
  cloud_run {
    service = google_cloud_run_service.frontend-svc.name
  }
}


# allow public invoke

resource "google_cloud_run_service_iam_member" "frontend-svc-perm" {
  service  = google_cloud_run_service.frontend-svc.name
  location = google_cloud_run_service.frontend-svc.location
  role     = "roles/run.invoker"
  member   = "allUsers"
  project = google_project.iap-test.project_id
}


resource "google_iap_web_backend_service_iam_binding" "frontend-binding" {
  project = google_project.iap-test.project_id
  web_backend_service = module.lb-store.backend_services["frontend"].name
  role = "roles/iap.httpsResourceAccessor"
  members = [
    "group:admgrp@liaurora.altostrat.com",
  ]
}




module "lb-store" {
  source  = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  
  create_url_map = false
  url_map = google_compute_url_map.store-urlmap.id
  project = google_project.iap-test.project_id
  name    = "store-lb"
  depends_on = [
     google_project_service.compute
  ]
  ssl                             = true
  managed_ssl_certificate_domains = ["frontend.liaurora.demo.altostrat.com"]
  https_redirect                  = true

  backends = {
    frontend = {
      description = null
      groups = [
        {
          group = google_compute_region_network_endpoint_group.frontend_neg.id
        }
      ]
      protocol                        = "HTTP"
      port                            = 80
      port_name                       = "http"
      timeout_sec                     = 10
      connection_draining_timeout_sec = null
      enable_cdn                      = false
      security_policy                 = null
      session_affinity                = null
      affinity_cookie_ttl_sec         = null
      custom_request_headers          = null
      custom_response_headers         = null
      enable_cdn             = false
      security_policy        = null
      custom_request_headers = null

      iap_config = {
        enable               = true
        oauth2_client_id     = google_iap_client.project_client.client_id
        oauth2_client_secret = google_iap_client.project_client.secret
      }
      log_config = {
        enable      = false
        sample_rate = null
      }
    }
    orders = {
      description = null
      groups = [
        {
          group = google_compute_region_network_endpoint_group.orders_neg.id
        }
      ]
      protocol                        = "HTTP"
      port                            = 80
      port_name                       = "http"
      timeout_sec                     = 10
      connection_draining_timeout_sec = null
      enable_cdn                      = false
      security_policy                 = null
      session_affinity                = null
      affinity_cookie_ttl_sec         = null
      custom_request_headers          = null
      custom_response_headers         = null
      enable_cdn             = false
      security_policy        = null
      custom_request_headers = null

      iap_config = {
        enable               = true
        oauth2_client_id     = google_iap_client.project_client.client_id
        oauth2_client_secret = google_iap_client.project_client.secret
      }
      log_config = {
        enable      = false
        sample_rate = null
      }
    }
    products = {
      description = null
      groups = [
        {
          group = google_compute_region_network_endpoint_group.products_neg.id
        }
      ]
      protocol                        = "HTTP"
      port                            = 80
      port_name                       = "http"
      timeout_sec                     = 10
      connection_draining_timeout_sec = null
      enable_cdn                      = false
      security_policy                 = null
      session_affinity                = null
      affinity_cookie_ttl_sec         = null
      custom_request_headers          = null
      custom_response_headers         = null
      enable_cdn             = false
      security_policy        = null
      custom_request_headers = null

      iap_config = {
        enable               = true
        oauth2_client_id     = google_iap_client.project_client.client_id
        oauth2_client_secret = google_iap_client.project_client.secret
      }
      log_config = {
        enable      = false
        sample_rate = null
      }
    }
  }
}


resource "google_compute_url_map" "store-urlmap" {
  // note that this is the name of the load balancer
  name            = "store-lb"
#   default_service = module.lb-store.backend_services["frontend"].self_link
  default_url_redirect {
      path_redirect = "/"
      strip_query = true
  }
  project = google_project.iap-test.project_id
  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }
  path_matcher {
    name            = "allpaths"
    default_service = module.lb-store.backend_services["frontend"].self_link

    path_rule {
      paths = [
        "/",
        "/*"
      ]
      service = module.lb-store.backend_services["frontend"].self_link
      
    }

    path_rule {
      paths = [
        "/api/orders",
        "/api/orders/*"
      ]
      service = module.lb-store.backend_services["orders"].self_link

    }

    path_rule {
      paths = [
        "/api/products",
        "/api/products/*"
      ]
      service = module.lb-store.backend_services["products"].self_link

    }

  }
}


# orders svc

resource "google_cloud_run_service" "orders-svc" {
  name     = "orders-svc"
  location = var.gcp_region
  project = google_project.iap-test.project_id
  metadata {
    annotations = {
      "run.googleapis.com/ingress" : "internal-and-cloud-load-balancing"
    }
  }
  template {
    metadata {
      annotations = {
        "run.googleapis.com/vpc-access-connector" : google_vpc_access_connector.connector.name
      }
    }
    spec {
      containers {
        image = var.orders_app_image
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

    depends_on = [google_project_service.run, google_project_iam_member.cepf]
}


resource "google_compute_region_network_endpoint_group" "orders_neg" {
  provider              = google
  name                  = "orders-neg"
  project = google_project.iap-test.project_id
  network_endpoint_type = "SERVERLESS"
  region                = var.gcp_region
  cloud_run {
    service = google_cloud_run_service.orders-svc.name
  }
  
}
# allow public invoke

resource "google_cloud_run_service_iam_member" "orders-svc-perm" {
  service  = google_cloud_run_service.orders-svc.name
  location = google_cloud_run_service.orders-svc.location
  role     = "roles/run.invoker"
  member   = "allUsers"
  project = google_project.iap-test.project_id
}


# products svc

resource "google_cloud_run_service" "products-svc" {
  name     = "products-svc"
  location = var.gcp_region
  project = google_project.iap-test.project_id
  metadata {
    annotations = {
      "run.googleapis.com/ingress" : "internal-and-cloud-load-balancing"
    }
  }
  template {
    metadata {
      annotations = {
        "run.googleapis.com/vpc-access-connector" : google_vpc_access_connector.connector.name
      }
    }
    spec {
      containers {
        image = var.products_app_image
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

    depends_on = [google_project_service.run, google_project_iam_member.cepf]
}


resource "google_compute_region_network_endpoint_group" "products_neg" {
  provider              = google
  name                  = "products-neg"
  project = google_project.iap-test.project_id
  network_endpoint_type = "SERVERLESS"
  region                = var.gcp_region
  cloud_run {
    service = google_cloud_run_service.products-svc.name
  }
  
}
# allow public invoke

resource "google_cloud_run_service_iam_member" "ordproductsers-svc-perm" {
  service  = google_cloud_run_service.products-svc.name
  location = google_cloud_run_service.products-svc.location
  role     = "roles/run.invoker"
  member   = "allUsers"
  project = google_project.iap-test.project_id
}

