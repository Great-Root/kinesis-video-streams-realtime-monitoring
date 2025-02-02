#!/bin/bash

# Function to validate environment
validate_environment() {
  local env=$1
  [[ "$env" == "dev" || "$env" == "staging" || "$env" == "prod" ]]
}

# Function to check if a workspace exists
workspace_exists() {
  local workspace=$1
  terraform workspace list | grep -q "^[* ] $workspace\$"
}

# Function to switch or create a workspace
switch_workspace() {
  local workspace=$1
  if workspace_exists "$workspace"; then
    echo "Switching to workspace '$workspace'."
    terraform workspace select "$workspace"
  else
    echo "Workspace '$workspace' does not exist. Creating it..."
    terraform workspace new "$workspace"
  fi
}

# Additional confirmation for prod environment
prod_confirmation() {
  echo "You are about to make changes to the 'prod' environment!"
  echo "This can affect live production systems. Proceed with caution."
  while true; do
    read -p "Type 'PROD' to confirm you understand the impact: " confirm
    if [[ "$confirm" == "PROD" ]]; then
      echo "Confirmation received. Proceeding with 'prod' environment."
      break
    else
      echo "Incorrect input. Please type 'PROD' to confirm."
    fi
  done
}

# Function to prompt user input for environment
prompt_environment() {
  local default_env="$1"
  while true; do
    read -p "Enter environment (dev, staging, prod) [default: $default_env]: " input_environment
    input_environment=${input_environment:-$default_env}
    if validate_environment "$input_environment"; then
      echo "$input_environment"
      break
    else
      echo "Invalid environment. Please enter one of: dev, staging, prod."
    fi
  done
}

# Main script logic
main() {
  local workspace="$1"

  if [[ -z "$workspace" ]]; then
    echo "No environment specified. Prompting for input."
    # Default to dev if not specified
    workspace=$(prompt_environment "dev")
  else
    # Validate environment if provided as an argument
    if ! validate_environment "$workspace"; then
      echo "Invalid environment: $workspace"
      echo "Valid environments: dev, staging, prod"
      exit 1
    fi
  fi

  # Additional confirmation for prod
  if [[ "$workspace" == "prod" ]]; then
    prod_confirmation
  fi

  # Navigate to Terraform directory
  SCRIPT_DIR="$(dirname "$0")"
  TERRAFORM_DIR="${SCRIPT_DIR}/terraform"

  if [[ ! -d "$TERRAFORM_DIR" ]]; then
    echo "Error: Terraform directory not found at $TERRAFORM_DIR"
    exit 1
  fi

  cd "$TERRAFORM_DIR" || exit 1

  # Switch to the specified workspace
  switch_workspace "$workspace"

  # Apply Terraform with the corresponding environment variables file
  TFVARS_FILE="environments/${workspace}.tfvars"

  if [[ ! -f "$TFVARS_FILE" ]]; then
    echo "Error: Terraform variable file not found for environment '$workspace': $TFVARS_FILE"
    exit 1
  fi

  echo "Running 'terraform apply' for workspace '$workspace' using $TFVARS_FILE..."
  terraform apply -var-file="$TFVARS_FILE"
  if [[ $? -eq 0 ]]; then
    echo "Terraform apply succeeded for workspace '$workspace'."
  else
    echo "Terraform apply failed for workspace '$workspace'."
    exit 1
  fi
}

# Run the script with the first argument as the environment (if provided)
main "$1"
