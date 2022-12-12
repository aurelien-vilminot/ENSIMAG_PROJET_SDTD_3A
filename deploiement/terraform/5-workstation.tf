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

    metadata_startup_script = "${file("${path.module}/scripts/workstation_launcher.sh")}"

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
            private_key = "${file("id_rsa")}"
            agent = "false"
        }
    }

    provisioner "file" {
        source = "${path.module}/scripts/kubespray_launcher.sh"
        destination = "/home/kubespray/kubespray_launcher.sh"

        connection {
            host = self.network_interface.0.access_config.0.nat_ip
            user = "kubespray"
            private_key = "${file("id_rsa")}"
            agent = "false"
        }
    }

    provisioner "file" {
        source = "${path.module}/../kubectl"
        destination = "/home/kubespray/kubectl"

        connection {
            host = self.network_interface.0.access_config.0.nat_ip
            user = "kubespray"
            private_key = "${file("id_rsa")}"
            agent = "false"
        }
    }

    service_account {
        email  = google_service_account.service_account.email
        scopes = ["cloud-platform", "compute-rw"]
    }
}