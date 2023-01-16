resource "google_compute_instance" "control_node_instance" {
    name = "controller-node"
    machine_type = "e2-medium"
    tags = [ "kubespray-network", "controller", "internal", "external"] // remove external
    boot_disk {
        initialize_params {
            image = "ubuntu-os-cloud/ubuntu-2204-lts"
            size = 20
        }
    }
    
    metadata = {
        ssh-keys = "kubespray:${file("id_rsa.pub")}"
    }

    metadata_startup_script = "${file("${path.module}/scripts/cluster_launcher.sh")}"

    depends_on = [ google_compute_subnetwork.vpc_subnet ]
    network_interface {
        subnetwork = google_compute_subnetwork.vpc_subnet.id

        access_config {

        }
    }
}