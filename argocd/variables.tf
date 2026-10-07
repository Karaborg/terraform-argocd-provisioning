variable "argocd_server" {
  description = "ArgoCD server URL, supplied by Jenkins or the local environment"
  type        = string
}

variable "argocd_username" {
  description = "ArgoCD service account username"
  type        = string
  sensitive   = true
}

variable "argocd_password" {
  description = "ArgoCD service account password"
  type        = string
  sensitive   = true
}

variable "project" {
  description = "ArgoCD project name"
  type        = string
}

variable "repo_url" {
  description = "Default Git repository URL"
  type        = string
}

variable "target_revision" {
  description = "Default Git branch or revision"
  type        = string
}

variable "namespace" {
  description = "Kubernetes destination namespace"
  type        = string
}

variable "destination_server" {
  description = "Kubernetes API server registered in ArgoCD"
  type        = string
  default     = "https://kubernetes.default.svc"
}

variable "applications" {
  description = "ArgoCD applications to create"

  type = map(object({
    path            = string
    values_file     = optional(string, "values.yaml")
    repo_url        = optional(string)
    target_revision = optional(string)
  }))
}
