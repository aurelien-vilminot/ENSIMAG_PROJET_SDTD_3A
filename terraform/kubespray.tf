data "external" "env" {
  program = ["${path.module}/scripts/env.sh"]
}

variable "number_workers" {
    type = number
    default = 2
}

provider "google" {
    project = data.external.env.result["GOOGLE_CLOUD_PROJECT"]
    region = "europe-west9"
    zone = "europe-west9-a"
}

resource "google_service_account" "service_account" {
  account_id   = "kubespray"
  display_name = "kubespray"
}

resource "google_project_iam_member" "member_project" {
  project = data.external.env.result["GOOGLE_CLOUD_PROJECT"]
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_compute_network" "vpc_network" {
    name = "kubespray-network"
    auto_create_subnetworks = false
    depends_on = [ google_service_account.service_account ]
}

resource "google_compute_subnetwork" "vpc_subnet" {
    name = "kubespray-subnetwork"
    ip_cidr_range = "10.200.0.0/24"
    depends_on = [ google_compute_network.vpc_network ]
    network = google_compute_network.vpc_network.id
}

resource "google_compute_firewall" "internal_rules" {
    name = "internal-rules"
    allow {
        protocol = "tcp"
    }
    allow {
        protocol = "udp"
    }
    allow {
        protocol = "icmp"
    }
    depends_on = [ google_compute_network.vpc_network ]
    network = google_compute_network.vpc_network.id
    priority = 1000
    source_ranges = [ "10.200.0.0/24" ]
    target_tags = [ "internal" ]
}

resource "google_compute_firewall" "external_rules" {
    name = "external-rules"
    allow {
        ports = [ "22", "80", "443", "6443"]
        protocol = "tcp"
    }
    allow {
        protocol = "icmp"
    }
    depends_on = [ google_compute_network.vpc_network ]
    network = google_compute_network.vpc_network.id
    priority = 1000
    source_ranges = [ "0.0.0.0/0" ]
    target_tags = [ "external" ]
}

resource "google_compute_instance" "workstation_instance" {
    name = "workstation"
    machine_type = "e2-medium"
    tags = [ "kubespray-network", "workstation", "internal", "external" ]
    boot_disk {
        initialize_params {
            image = "ubuntu-os-cloud/ubuntu-2204-lts"
        }
    }

    metadata = {
        ssh-keys = "kubespray:${file("id_rsa.pub")}"
    }

    metadata_startup_script = file("${path.module}/scripts/workstation_launcher.sh")

    depends_on = [ google_compute_subnetwork.vpc_subnet, google_compute_instance.control_node_instance, google_compute_instance.worker_node_instance ]
    network_interface {
        subnetwork = google_compute_subnetwork.vpc_subnet.id

        access_config {
        }
    }

    provisioner "file" {
        source = "${path.module}/id_rsa"
        destination = "/home/kubespray/.ssh/id_rsa"

        connection {
            host = self.network_interface.0.access_config.0.nat_ip
            user = "kubespray"
            private_key = file("id_rsa")
            agent = "false"
        }
    }

    provisioner "file" {
        source = "${path.module}/scripts/kubespray_launcher.sh"
        destination = "/home/kubespray/kubespray_launcher.sh"

        connection {
            host = self.network_interface.0.access_config.0.nat_ip
            user = "kubespray"
            private_key = file("id_rsa")
            agent = "false"
        }
    }

    service_account {
        email  = google_service_account.service_account.email
        scopes = ["cloud-platform", "compute-rw"]
    }
}

resource "google_compute_instance" "control_node_instance" {
    name = "controller-node"
    machine_type = "e2-small"
    tags = [ "kubespray-network", "controller", "internal", "external"] // remove external
    boot_disk {
        initialize_params {
            image = "ubuntu-os-cloud/ubuntu-2204-lts"
        }
    }
    
    metadata = {
        ssh-keys = "kubespray:${file("id_rsa.pub")}"
    }

    metadata_startup_script = file("${path.module}/scripts/cluster_launcher.sh")

    depends_on = [ google_compute_subnetwork.vpc_subnet ]
    network_interface {
        subnetwork = google_compute_subnetwork.vpc_subnet.id

        access_config {

        }
    }
}

resource "google_compute_instance" "worker_node_instance" {
    count = var.number_workers
    name = "worker-node-${count.index}"
    machine_type = "e2-small"
    tags = [ "kubespray-network", "worker", "internal", "external" ] // remove external
    boot_disk {
        initialize_params {
            image = "ubuntu-os-cloud/ubuntu-2204-lts"
        }
    }

    metadata = {
        ssh-keys = "kubespray:${file("id_rsa.pub")}"
    }

    metadata_startup_script = file("${path.module}/scripts/cluster_launcher.sh")

    depends_on = [ google_compute_subnetwork.vpc_subnet ]
    network_interface {
        subnetwork = google_compute_subnetwork.vpc_subnet.id

        access_config {

        }
    }
}

resource "google_compute_instance" "prometheus_instance" {
    name = "prometheus"
    machine_type = "e2-small"
    tags = [ "prometheus", "internal", "external" ] // remove external
    boot_disk {
        device_name = "boot"
        auto_delete = false
        initialize_params {
            image = "ubuntu-os-cloud/ubuntu-2204-lts"
            size = 20
            type = "pd-standard"
        }
    }

    metadata_startup_script = file("${path.module}/scripts/cluster_launcher.sh")

    network_interface {
        subnetwork = google_compute_subnetwork.vpc_subnet.id

        access_config {
        }
    }
}

# output "var" {
#     value = google_compute_instance.workstation_instance.network_interface.0.access_config.0.nat_ip
# }

#scope for controller + workers
#     --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring
