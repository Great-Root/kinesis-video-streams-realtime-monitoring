#!/bin/bash

# Function to validate environment
validate_environment() {
  local env=$1
  [[ "$env" == "dev" || "$env" == "staging" || "$env" == "prod" ]]
}

# Navigate to Terraform directory
SCRIPT_DIR="$(dirname "$0")"
TERRAFORM_DIR="${SCRIPT_DIR}/terraform"

if [[ ! -d "$TERRAFORM_DIR" ]]; then
  echo "Error: Terraform directory not found at $TERRAFORM_DIR"
  exit 1
fi

cd "$TERRAFORM_DIR" || exit 1

# Function to read value from environment-specific terraform.tfvars
get_tfvar() {
  local env=$1
  local key=$2
  local tfvars_file="environments/${env}.tfvars"
  if [[ -f "$tfvars_file" ]]; then
    awk -F'=' -v key="$key" '$1 ~ key {gsub(/^[ \t"]+|[ \t"]+$/, "", $2); print $2}' "$tfvars_file"
  fi
}

# Function to update or append key-value pairs in terraform.tfvars
update_tfvars() {
  local env=$1
  local key="$2"
  local value="$3"
  local tfvars_file="environments/${env}.tfvars"

  if [[ ! -f "$tfvars_file" ]]; then
    touch "$tfvars_file"
  fi

  if grep -qE "^\s*${key}\s*=" "$tfvars_file"; then
    awk -v key="$key" -v value="$value" '
    BEGIN { updated = 0 }
    $1 == key && $2 == "=" {
      print key " = \"" value "\""
      updated = 1
      next
    }
    { print }
    END {
      if (updated == 0) {
        print key " = \"" value "\""
      }
    }' "$tfvars_file" > "${tfvars_file}.tmp" && mv "${tfvars_file}.tmp" "$tfvars_file"
  else
    echo "${key} = \"$value\"" >> "$tfvars_file"
  fi
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

# Get environment input
ENVIRONMENT=$(prompt_environment "dev")

# Ensure environment variable file exists
TFVARS_FILE="environments/${ENVIRONMENT}.tfvars"
if [[ ! -f "$TFVARS_FILE" ]]; then
  touch "$TFVARS_FILE"
fi

# Load values from tfvars file, if they exist
PROJECT_NAME=$(get_tfvar "$ENVIRONMENT" "project_name")
AWS_REGION=$(get_tfvar "$ENVIRONMENT" "region")

# Ask user for missing values
read -p "Enter project name [default: ${PROJECT_NAME:-}]: " input_project_name
PROJECT_NAME=${input_project_name:-$PROJECT_NAME}

read -p "Enter AWS region [default: ${AWS_REGION:-}]: " input_region
AWS_REGION=${input_region:-$AWS_REGION}

# Update terraform.tfvars with values
update_tfvars "$ENVIRONMENT" "project_name" "$PROJECT_NAME"
update_tfvars "$ENVIRONMENT" "region" "$AWS_REGION"

# Backend resources
S3_BUCKET_NAME="${PROJECT_NAME}-terraform-state-bucket"
DYNAMODB_TABLE_NAME="${PROJECT_NAME}-terraform-locks"

update_tfvars "$ENVIRONMENT" "backend_bucket_name" "$S3_BUCKET_NAME"
update_tfvars "$ENVIRONMENT" "backend_dynamodb_table" "$DYNAMODB_TABLE_NAME"

# Ensure S3 bucket exists
echo "Ensuring S3 bucket exists: $S3_BUCKET_NAME"
if ! aws s3api head-bucket --bucket "$S3_BUCKET_NAME" 2>/dev/null; then
  echo "Creating S3 bucket: $S3_BUCKET_NAME"
  if [[ "$AWS_REGION" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "$S3_BUCKET_NAME" >/dev/null 2>&1
  else
    aws s3api create-bucket --bucket "$S3_BUCKET_NAME" --region "$AWS_REGION" --create-bucket-configuration LocationConstraint="$AWS_REGION" >/dev/null 2>&1
  fi
  if [[ $? -eq 0 ]]; then
    echo "S3 bucket $S3_BUCKET_NAME created successfully."
  else
    echo "Error: Failed to create S3 bucket $S3_BUCKET_NAME." >&2
    exit 1
  fi
  aws s3api put-bucket-versioning --bucket "$S3_BUCKET_NAME" --versioning-configuration Status=Enabled >/dev/null 2>&1
else
  echo "S3 bucket $S3_BUCKET_NAME already exists."
fi

# Ensure DynamoDB table exists
echo "Ensuring DynamoDB table exists: $DYNAMODB_TABLE_NAME"
if ! aws dynamodb describe-table --table-name "$DYNAMODB_TABLE_NAME" >/dev/null 2>&1; then
  echo "Creating DynamoDB table: $DYNAMODB_TABLE_NAME"
  aws dynamodb create-table --table-name "$DYNAMODB_TABLE_NAME" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST >/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    echo "DynamoDB table $DYNAMODB_TABLE_NAME created successfully."
  else
    echo "Error: Failed to create DynamoDB table $DYNAMODB_TABLE_NAME." >&2
    exit 1
  fi
else
  echo "DynamoDB table $DYNAMODB_TABLE_NAME already exists."
fi


# Generate backend.tf dynamically
BACKEND_FILE="backend.tf"
cat <<EOF > "$BACKEND_FILE"
terraform {
  backend "s3" {
    bucket         = "$S3_BUCKET_NAME"
    key            = "state/terraform.tfstate"
    region         = "$AWS_REGION"
    dynamodb_table = "$DYNAMODB_TABLE_NAME"
    encrypt        = true
  }
}
EOF

# Terraform workspace setup
echo "Setting up Terraform workspace..."
terraform init -input=false -reconfigure

WORKSPACE_EXISTS=$(terraform workspace list | grep -E "^\*?\s*${ENVIRONMENT}\s*$")

if [[ -z "$WORKSPACE_EXISTS" ]]; then
  terraform workspace new "$ENVIRONMENT"
else
  terraform workspace select "$ENVIRONMENT"
fi

echo "Terraform workspace setup complete."

# Finalize Terraform initialization
echo "Terraform initialized successfully! You can now use 'terraform plan' and 'terraform apply -var-file=$TFVARS_FILE'."
