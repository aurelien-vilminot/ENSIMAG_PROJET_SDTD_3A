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

    metadata_startup_script = "${file("${path.module}/scripts/cluster_launcher.sh")}"

    network_interface {
        subnetwork = google_compute_subnetwork.vpc_subnet.id

        access_config {
        }
    }
}