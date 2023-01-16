#################################################
##### CD Application WIF Account Uat ENV ########
#################################################

resource "google_service_account" "sa_github_uat" {
  project      = var.uat_project_id
  account_id   = "sa-gha-${var.uat_project_id}"
  display_name = "SA for the service Github actions"
}


resource "google_project_iam_member" "github_actions_access_uat" {
  project = var.uat_project_id
  member  = google_service_account.sa_github_uat.member
  role    = each.value
  for_each = toset([
    "roles/artifactregistry.admin",
    "roles/containerregistry.ServiceAgent",
    "roles/artifactregistry.reader",
    "roles/artifactregistry.admin",
    "roles/viewer",
    "roles/run.viewer",
    "roles/binaryauthorization.attestorsAdmin",
    "roles/storage.objectAdmin",
    "roles/iam.serviceAccountKeyAdmin",
    "roles/cloudkms.cryptoOperator",
    "roles/containeranalysis.occurrences.editor",
    "roles/containeranalysis.notes.attacher",
     "roles/run.developer",
     "roles/iam.serviceAccountUser",
  ])
}


resource "google_project_iam_member" "github_actions_access_uat_cicd" {
  project = var.cicd_project_id
  member  = google_service_account.sa_github_uat.member
  role    = each.value
  for_each = toset([

    "roles/artifactregistry.admin",
    "roles/viewer",
  ])
}


resource "google_iam_workload_identity_pool" "github_pool_uat" {
  project                   = var.uat_project_id
  workload_identity_pool_id = "github-pl-${var.uat_project_id}"
  display_name              = "Github actions authentication"
  description               = "Identity pool for automated  delievery"
  disabled                  = false
}

resource "google_iam_workload_identity_pool_provider" "github_provider_uat" {
  project                            = var.uat_project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool_uat.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions-provider"
  display_name                       = "Github actions provider"
  disabled                           = false
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
  depends_on = [
    google_iam_workload_identity_pool.github_pool_uat
  ]
}

resource "google_service_account_iam_binding" "github_account_binding_uat" {
  service_account_id = google_service_account.sa_github_uat.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool_uat.name}/attribute.repository/groupm-global/mcm-createlift-web-app",
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool_uat.name}/attribute.repository/groupm-global/mcm-createlift-yougov-data",
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool_uat.name}/attribute.repository/groupm-global/mcm-createlift-nielsen-data",
  ]
}
