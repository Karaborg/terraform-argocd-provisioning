terraform {
  required_providers {
    argocd = {
      source = "argoproj-labs/argocd"
    }
  }
}

provider "argocd" {
  server_addr = var.argocd_server
  username    = var.argocd_username
  password    = var.argocd_password
}