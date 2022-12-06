provider "google" {
    project = "prom-vm"
    region = "europe-west9"
    zone = "europe-west9-a"
}

resource "google_compute_network" "vpc_network" {
    name = "prometheus-network"
    auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vpc_subnet" {
    name = "prometheus-subnetwork"
    ip_cidr_range = "10.200.0.0/24"
    depends_on = [ google_compute_network.vpc_network ]
    network = google_compute_network.vpc_network.id
}

resource "google_compute_firewall" "allow_ssh" {
    name = "allow-ssh"
    allow {
        ports = [ "22" ]
        protocol = "tcp"
    }
    direction = "INGRESS"
    network = google_compute_network.vpc_network.id
    priority = 1000
    source_ranges = [ "0.0.0.0/0" ]
    target_tags = [ "ssh" ]
}

resource "google_compute_firewall" "allow_http" {
    name = "allow-http"
    allow {
        ports = [ "80", "443", "9090" ]
        protocol = "tcp"
    }
    direction = "INGRESS"
    network = google_compute_network.vpc_network.id
    priority = 1000
    source_ranges = [ "0.0.0.0/0" ]
    target_tags = [ "http", "https" ]
}

resource "google_compute_instance" "default" {
    name = "prometheus-server"
    machine_type = "e2-medium"
    tags = [ "prometheus", "server", "ssh", "http", "https" ]

    boot_disk {
        device_name = "boot"
        auto_delete = false
        initialize_params {
            image = "ubuntu-os-cloud/ubuntu-2204-lts"
            size = 20
            type = "pd-standard" # or pd-ssd, pd-balanced
        }
    }

    # Initialize Prometheus
    metadata_startup_script = "sudo apt update; sudo apt install -yq prometheus"

    network_interface {
        subnetwork = google_compute_subnetwork.vpc_subnet.id

        access_config {
            # Include this section to give the VM an external IP address
        }
    }
}
