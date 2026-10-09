resource "google_compute_network" "vpc" {
  name                    = "gke-vpc"
  auto_create_subnetworks = false
}

############################################################

resource "google_compute_subnetwork" "subnet" {
  name          = "gke-subnet"
  ip_cidr_range = "10.10.0.0/24"

  region  = var.region
  network = google_compute_network.vpc.id

  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.20.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.30.0.0/20"
  }
}

############################################################

resource "google_compute_router" "router" {
  name    = "gke-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

############################################################

resource "google_compute_router_nat" "nat" {
  name   = "gke-nat"
  router = google_compute_router.router.name
  region = var.region

  nat_ip_allocate_option = "AUTO_ONLY"

  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

############################################################

resource "google_compute_firewall" "allow_all" {
  name    = "allow-all"
  network = google_compute_network.vpc.name

  allow {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
}

##################################

resource "google_compute_instance" "bastion" {

  name         = "bastion"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {}
  }

}



#####################################################
resource "google_container_cluster" "gke" {

  name     = "murthy"
  location = var.zone

  deletion_protection = false

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.id

  remove_default_node_pool = true
  initial_node_count       = 2

  networking_mode = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  private_cluster_config {

    enable_private_nodes    = true
    enable_private_endpoint = false

    master_ipv4_cidr_block = "172.16.0.0/28"
  }
}

# ############################################################

resource "google_container_node_pool" "primary_nodes" {
  name     = "primary-node-pool"
  location = var.zone
  cluster  = google_container_cluster.gke.name

  node_count = 2

  autoscaling {
    min_node_count = 2
    max_node_count = 3
  }

  node_config {
    machine_type = "e2-medium"
    disk_size_gb = 30

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
