# Legacy shell.nix for non-flake users
{ pkgs ? import <nixpkgs> {} }:

let
  pythonEnv = pkgs.python3.withPackages (ps: with ps; [
    mkdocs
    mkdocs-material
    markdown
    pygments
  ]);
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    # Terraform and cloud tools
    terraform
    terraform-docs
    tflint
    
    # Kubernetes tools
    kubectl
    kubernetes-helm
    
    # Google Cloud SDK
    google-cloud-sdk
    
    # Documentation tools
    pythonEnv
    
    # Development tools
    git
    jq
    yq
    curl
    wget
  ];

  shellHook = ''
    echo "🚀 Terraform GKE Private Deployment Environment"
    echo ""
    echo "Available tools:"
    echo "  - terraform: $(terraform version | head -n1)"
    echo "  - kubectl: $(kubectl version --client --short 2>/dev/null || echo 'installed')"
    echo "  - helm: $(helm version --short 2>/dev/null || echo 'installed')"
    echo "  - gcloud: $(gcloud version | head -n1)"
    echo ""
    echo "To start the documentation server:"
    echo "  make docs-serve"
    echo ""
  '';
}