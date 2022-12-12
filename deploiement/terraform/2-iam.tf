resource "google_service_account" "service_account" {
  account_id   = "kubespray"
  display_name = "kubespray"
}

resource "google_project_iam_member" "member_project" {
  project = data.external.env.result["GOOGLE_CLOUD_PROJECT"]
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}