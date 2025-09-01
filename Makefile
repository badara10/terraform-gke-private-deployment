# Makefile for Terraform GKE Private Deployment

.PHONY: help init plan apply destroy clean docs-serve docs-build test validate fmt

# Default target
help:
	@echo "Terraform GKE Private Deployment - Available targets:"
	@echo ""
	@echo "  make init        - Initialize Terraform in examples/dev"
	@echo "  make plan        - Plan infrastructure changes"
	@echo "  make apply       - Apply infrastructure changes"
	@echo "  make destroy     - Destroy all infrastructure"
	@echo "  make clean       - Clean Terraform files"
	@echo ""
	@echo "  make docs-serve  - Start local documentation server"
	@echo "  make docs-build  - Build documentation site"
	@echo ""
	@echo "  make validate    - Validate all Terraform configurations"
	@echo "  make fmt         - Format all Terraform files"
	@echo "  make test        - Run basic tests"
	@echo ""

# Terraform commands
init:
	@echo "Initializing Terraform..."
	@cd examples/dev && terraform init

plan:
	@echo "Planning infrastructure changes..."
	@cd examples/dev && terraform plan

apply:
	@echo "Applying infrastructure changes..."
	@cd examples/dev && terraform apply

destroy:
	@echo "Destroying infrastructure..."
	@cd examples/dev && terraform destroy

clean:
	@echo "Cleaning Terraform files..."
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.tfstate*" -exec rm -f {} + 2>/dev/null || true
	@find . -type f -name ".terraform.lock.hcl" -exec rm -f {} + 2>/dev/null || true
	@echo "Cleaned!"

# Documentation commands
docs-serve:
	@echo "Starting documentation server on http://localhost:8000..."
	@cd docs && python3 -m mkdocs serve --dev-addr=0.0.0.0:8000

docs-build:
	@echo "Building documentation site..."
	@cd docs && python3 -m mkdocs build

# Validation and formatting
validate:
	@echo "Validating Terraform configurations..."
	@echo "Validating GKE module..."
	@cd modules/gke && terraform init -backend=false && terraform validate
	@echo "Validating Helm module..."
	@cd modules/helm_app && terraform init -backend=false && terraform validate
	@echo "Validating dev example..."
	@cd examples/dev && terraform init -backend=false && terraform validate
	@echo "All configurations are valid!"

fmt:
	@echo "Formatting Terraform files..."
	@terraform fmt -recursive .
	@echo "Formatting complete!"

# Testing
test: validate
	@echo "Running basic tests..."
	@echo "Checking required files..."
	@test -f modules/gke/main.tf || (echo "GKE module missing!" && exit 1)
	@test -f modules/helm_app/main.tf || (echo "Helm module missing!" && exit 1)
	@test -f examples/dev/main.tf || (echo "Dev example missing!" && exit 1)
	@test -f docs/index.md || (echo "Documentation missing!" && exit 1)
	@echo "All tests passed!"

# Install documentation dependencies
docs-deps:
	@echo "Installing documentation dependencies..."
	@pip3 install mkdocs mkdocs-material markdown pygments
	@echo "Dependencies installed!"

# Quick setup for new users
setup: docs-deps init
	@echo "Setup complete! Run 'make plan' to review infrastructure changes."