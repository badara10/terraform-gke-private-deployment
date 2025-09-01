variable "credentials_file" {
  description = "Path to the GCP service account credentials JSON file"
  type        = string
  default     = "/home/badara/CREDENTIALS/crucial-respect-470815-u3-be030965253b.json"
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "crucial-respect-470815-u3"
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
  default     = "private-gke-cluster"
}

variable "create_vpc" {
  description = "Whether to create a new VPC or use an existing one"
  type        = bool
  default     = true
}

variable "vpc_name" {
  description = "The name of the VPC network"
  type        = string
  default     = "gke-vpc"
}

variable "subnet_name" {
  description = "The name of the subnet"
  type        = string
  default     = "gke-subnet"
}

variable "node_count" {
  description = "Number of nodes in the node pool"
  type        = number
  default     = 3
}

variable "machine_type" {
  description = "Machine type for the nodes"
  type        = string
  default     = "e2-medium"
}

variable "preemptible" {
  description = "Whether to use preemptible nodes"
  type        = bool
  default     = false
}