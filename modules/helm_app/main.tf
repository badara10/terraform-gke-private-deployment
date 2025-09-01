resource "kubernetes_namespace" "app" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
  }
}

resource "helm_release" "hello_nginx" {
  name       = var.release_name
  namespace  = var.namespace
  chart      = "nginx"
  repository = "https://charts.bitnami.com/bitnami"
  version    = var.chart_version

  values = [
    yamlencode({
      service = {
        type = "LoadBalancer"
        port = 80
      }
      resources = var.resources
      replicaCount = var.replica_count
      
      # Custom nginx configuration for hello world
      serverBlock = <<-EOT
        server {
          listen 8080;
          location / {
            return 200 '<html><body><h1>Hello from nginx!</h1></body></html>';
            add_header Content-Type text/html;
          }
        }
      EOT
    })
  ]


  depends_on = [kubernetes_namespace.app]
}