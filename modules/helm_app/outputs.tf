output "release_name" {
  description = "The name of the Helm release"
  value       = helm_release.hello_nginx.name
}

output "release_namespace" {
  description = "The namespace of the Helm release"
  value       = helm_release.hello_nginx.namespace
}

output "release_status" {
  description = "The status of the Helm release"
  value       = helm_release.hello_nginx.status
}

output "release_version" {
  description = "The version of the Helm release"
  value       = helm_release.hello_nginx.version
}