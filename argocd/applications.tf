resource "argocd_application" "applications" {
  for_each = var.applications

  metadata {
    name = each.key
  }

  spec {
    project                = var.project
    revision_history_limit = 0

    source {
      repo_url = coalesce(
        each.value.repo_url,
        var.repo_url
      )

      path = each.value.path

      target_revision = coalesce(
        each.value.target_revision,
        var.target_revision
      )

      helm {
        value_files = [
          each.value.values_file
        ]
      }
    }

    destination {
      server    = var.destination_server
      namespace = var.namespace
    }
  }
}