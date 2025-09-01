variable "release_name" {
  description = "The name of the Helm release"
  type        = string
  default     = "hello-nginx"
}

variable "namespace" {
  description = "The Kubernetes namespace to deploy the application"
  type        = string
  default     = "default"
}

variable "create_namespace" {
  description = "Whether to create the namespace if it doesn't exist"
  type        = bool
  default     = true
}

variable "chart_version" {
  description = "The version of the nginx Helm chart"
  type        = string
  default     = "13.2.10"
}

variable "replica_count" {
  description = "Number of nginx replicas"
  type        = number
  default     = 2
}

variable "resources" {
  description = "Resource limits and requests for the pods"
  type = object({
    limits = object({
      cpu    = string
      memory = string
    })
    requests = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    limits = {
      cpu    = "100m"
      memory = "128Mi"
    }
    requests = {
      cpu    = "50m"
      memory = "64Mi"
    }
  }
}

