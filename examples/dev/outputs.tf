output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.gke.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint for the GKE cluster"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "cluster_region" {
  description = "The region of the GKE cluster"
  value       = module.gke.region
}

output "hello_nginx_release_name" {
  description = "The name of the hello-nginx Helm release"
  value       = module.hello_nginx.release_name
}

output "hello_nginx_namespace" {
  description = "The namespace where hello-nginx is deployed"
  value       = module.hello_nginx.release_namespace
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${module.gke.region} --project ${var.project_id}"
}