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