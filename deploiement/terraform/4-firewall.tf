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
        ports = [ "22", "80", "443", "6443", "32000", "32001", "32002"]
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