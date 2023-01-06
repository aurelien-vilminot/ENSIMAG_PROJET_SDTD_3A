resource "google_service_account" "service_account" {
  account_id   = "kubespray"
  display_name = "kubespray"
}

resource "google_project_iam_member" "member_project" {
  project = data.external.env.result["GOOGLE_CLOUD_PROJECT"]
  for_each = toset([
    "roles/compute.admin",
    "roles/logging.logWriter",
  ])
  role    = each.key
  member  = "serviceAccount:${google_service_account.service_account.email}"
}
