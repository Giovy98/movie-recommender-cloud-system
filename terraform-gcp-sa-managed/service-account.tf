resource "google_project_iam_member" "assign_role" {
  for_each = toset(local.roles)
  project  = local.project_id
  role     = each.key
  member   = "serviceAccount:${local.service_account}"
  
}