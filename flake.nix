{
  description = "Terraform GKE Private Deployment Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Python environment for documentation server
        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          mkdocs
          mkdocs-material
          markdown
          pygments
        ]);
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Terraform and cloud tools
            terraform
            terraform-docs
            tflint
            tfsec
            
            # Kubernetes tools
            kubectl
            kubernetes-helm
            k9s
            
            # Google Cloud SDK
            google-cloud-sdk
            
            # Documentation tools
            pythonEnv
            mdbook
            
            # Development tools
            git
            jq
            yq
            curl
            wget
            
            # Editor support
            yaml-language-server
            terraform-ls
          ];

          shellHook = ''
            echo "🚀 Terraform GKE Private Deployment Environment"
            echo ""
            echo "Available tools:"
            echo "  - terraform: $(terraform version | head -n1)"
            echo "  - kubectl: $(kubectl version --client --short 2>/dev/null || echo 'installed')"
            echo "  - helm: $(helm version --short)"
            echo "  - gcloud: $(gcloud version | head -n1)"
            echo "  - mkdocs: available for documentation"
            echo ""
            echo "Quick commands:"
            echo "  make docs-serve  - Start documentation server"
            echo "  make init        - Initialize Terraform"
            echo "  make plan        - Plan infrastructure changes"
            echo "  make apply       - Apply infrastructure changes"
            echo "  make destroy     - Destroy infrastructure"
            echo ""
            echo "Documentation server can be started with:"
            echo "  cd docs && mkdocs serve"
            echo ""
          '';

          # Environment variables
          GOOGLE_APPLICATION_CREDENTIALS = "\${GOOGLE_APPLICATION_CREDENTIALS:-}";
          KUBECONFIG = "\${KUBECONFIG:-$HOME/.kube/config}";
        };

        # App for running documentation server
        apps.docs-server = flake-utils.lib.mkApp {
          drv = pkgs.writeShellScriptBin "docs-server" ''
            #!/usr/bin/env bash
            echo "Starting documentation server..."
            cd docs && ${pythonEnv}/bin/mkdocs serve --dev-addr=0.0.0.0:8000
          '';
        };

        # Package the documentation
        packages.docs = pkgs.stdenv.mkDerivation {
          pname = "terraform-gke-docs";
          version = "1.0.0";
          src = ./docs;
          
          buildInputs = [ pythonEnv ];
          
          buildPhase = ''
            mkdocs build
          '';
          
          installPhase = ''
            mkdir -p $out
            cp -r site/* $out/
          '';
        };
      });
}