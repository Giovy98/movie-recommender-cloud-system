resource "google_project_service" "api" {
  for_each           = toset(local.apis)
  service            = each.key
  disable_on_destroy = false
}

resource "google_project_iam_member" "assign_role" {
  for_each = toset(local.roles)
  project  = local.project_id
  role     = each.key
  member   = "serviceAccount:${local.service_account}"
  
}