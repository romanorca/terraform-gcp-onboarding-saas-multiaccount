locals {
  gcp_permissions = jsondecode(file("${path.module}/gcp_permissions.json"))
  orca_production_project_number = "788120191304"
}

resource "google_service_account" "orca" {
  account_id   = "orcasecurity-side-scanner"
  project      = var.project_id
  display_name = "Orca Security Side Scanning Service Account"
}

resource "google_service_account_key" "orca" {
  service_account_id = google_service_account.orca.name
}

resource "local_file" "orca" {
  content  = base64decode(google_service_account_key.orca.private_key)
  filename = "${path.module}/service_account_key_orca.json"
}

resource "google_organization_iam_custom_role" "orca-custom-role" {
  role_id      = "orca_side_scanner"
  title        = "orca-side-scanner-role"
  permissions  = concat(local.gcp_permissions.base, local.gcp_permissions.saas_extras, local.gcp_permissions.organization)
  org_id       = var.organization_id
}

resource "google_organization_iam_member" "organization-membership-1" {
  org_id  = var.organization_id
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.orca.email}"
}

resource "google_organization_iam_member" "organization-membership-2" {
  org_id  = var.organization_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.orca.email}"
}

resource "google_organization_iam_member" "organization-membership-3" {
  org_id  = var.organization_id
  role    = "roles/iam.securityReviewer"
  member  = "serviceAccount:${google_service_account.orca.email}"
}

resource "google_organization_iam_member" "organization-membership-4" {
  org_id  = var.organization_id
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member  = "serviceAccount:service-${local.orca_production_project_number}@compute-system.iam.gserviceaccount.com"
}

resource "google_organization_iam_binding" "organization-binding-1" {
  org_id  = var.organization_id
  role    = "organizations/${var.organization_id}/roles/${google_organization_iam_custom_role.orca-custom-role.role_id}"
  members = [
    "serviceAccount:${google_service_account.orca.email}",
  ]
}

resource "google_project_service" "service" {
  count   = length(local.gcp_permissions.api_services)
  project = var.project_id
  service = local.gcp_permissions.api_services[count.index]
}
