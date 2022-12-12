provider "google" {
    project = data.external.env.result["GOOGLE_CLOUD_PROJECT"]
    region  = var.region
    zone    = "${var.region}-a"
}
