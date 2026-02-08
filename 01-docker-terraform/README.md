# Docker
Everything will be run on VS Code terminal using bash:
1. Check your installed docker, run: `docker`
2. Create and run container from image, run: `docker run [image name]`
3. Create Docker YAML file, python code for download data, and check dependencies file (pyproject.toml)
4. Activate using: `docker compose up`
5. Verify running container: `docker ps`
6. Initialize Python Environment (uv): `uv sync`. Also if needed, install dependencies: `uv add pandas pyarrow sqlalchemy psycopg2-binary requests`
7. Download data: `uv run python [your/scripts/to/download_data.py]`
8. Load Data into PostgreSQL: `uv run python [your/scripts/to/load_to_postgres.py]`
9. Access postgresSQL using PgAdmin (http://localhost:8085) and verify database and tables exist. Start inspect data and querying.
10. Deactivate using: `docker compose down`

Notes: Docker runs the database, uv runs Python, VS Code is just the control panel.

# Terraform
*Official HashiCorp Method*

We will (All inside bash):
1. Add HashiCorp GPG key
2. Add HashiCorp APT repository
3. Install Terraform
4. Verify installation

## STEP 1 — Update Base Packages
```bash
sudo apt update
sudo apt install -y gnupg software-properties-common curl
```

Why:
- gnupg → verify signatures
- software-properties-common → manage repos
- curl → download keys

## STEP 2 — Add HashiCorp GPG Key
```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
```

This allows Ubuntu to trust HashiCorp packages.

## STEP 3 — Add HashiCorp Repository
```bash
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
```

This tells Ubuntu: “Terraform lives here.”

## STEP 4 — Update Package List Again
```bash
sudo apt update
```

## STEP 5 — Install Terraform
```bash
sudo apt install -y terraform
```

## STEP 6 — Verify Installation & Next step
```bash
terraform --version
```
Expected output (example): Terraform v1.x.x

Continue to the course or explore more via [Terraform Docs](https://developer.hashicorp.com/terraform/docs) or via terminal:

```bash
terraform -help
```

# Explore Terraform Course
## Main commands used on the course:
1. init: Prepare your working directory for other commands
2. plan: Show changes required by the current configuration
3. apply: Create or update infrastructure
4. destroy: Destroy previously-created infrastructure

## Terraform Basics 
In my case, I use GCP (Google Cloud Platform)
1. Open Cloud Service --> Create Project --> Setting up Service Account
2. Managing Keys (Caution: Never share the key and include it in gitignore!!!)
3. Creating `main.tf` file --> Reformat the code to standard format using `terraform fmt`
4. Setting up credentials and providers
    - Option a: put the credentials on your `main.tf` under provider section
        ```
        provider "google" {
            credentials = "./your/google/credentials/file.json"
            project = "your-proj-name"
            region  = "us-central1"
            }
        ```
    - Option b: generate Application Default Credentials (ADC) via your terminal
        ```bash
        gcloud auth application-default login
        ```
    - Option c (**used in this course**): set an environment variable in your terminal session
        ```bash
        export GOOGLE_CREDENTIALS="./your/google/credentials/file.json"
        ```
        Check it with:
        ```bash
        echo $GOOGLE_CREDENTIALS
        ```
5. Initialize using `terraform init`
6. Creating a storage bucket on GCP
7. Plan what to apply and show changes before apply with `terraform plan`
8. Create the infra with `terraform apply`
9. Delete the infra with `terraform destroy` (PS: always do this for this course and for the sake of your wallet !!!)

## Terraform Variables
1. Creating a big query dataset --> add variable in `main.tf`
2. Using variables --> create `variables.tf` file. The variables you need to create are `project`, `region`, `location`, dataset name (`bq_dataset_name`), bucket name (`gcs_bucket_name`), and storage class (`gcs_storage_class`)
3. Using function file() in `main.tf` file:
    - Create variable for `credentials` in `variables.tf` file
    - We need to unset the GOOGLE_CREDENTIALS environment variable on your local machine:
        ```bash
        unset GOOGLE_CREDENTIALS
        ```
    - Check it again, it should be gone, with:
        ```bash
        echo $GOOGLE_CREDENTIALS
        ```
    - Update the credentials on your `main.tf` under provider section
        ```
        provider "google" {
            credentials = file(var.credentials)
            project = var.project
            region  = var.region
            }
        ```

## Terraform Variables
For some reason, I won't share my `variables.tf` file in this repo. But I will share the modified version, so here it is the complete code. For this course, edit the one inside the square brackets "[ ]".
```
variable "credentials" {
    description = "The path to the credentials file"
    default     = "[your-credentials-file-location]"
}

variable "project" {
    description = "The project ID"
    default     = "[your-project-name-or-ID]"
}

variable "region" {
    description = "The region of the Project"
    default     = "us-central1"
}

variable "location" {
    description = "The location of the Project"
    default     = "US"
}

variable "bq_dataset_name" {
    description = "The name of the BigQuery dataset to create"
    default     = "[your-dataset-name]"
}

variable "gcs_bucket_name" {
    description = "The name of the GCS bucket to create"
    default     = "[your-bucket-name]"
}

variable "gcs_storage_class" {
    description = "The storage class of the GCS bucket"
    default     = "STANDARD"
}
```

# NOTES
Complete Course: https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/01-docker-terraform/README.md

Tips to shorter working directory information in the terminal using bash:
```bash
PS1="> "
```

## Install GCloud SDK via official Google repo

STEP 1 — Update package list
```bash
sudo apt-get update
```

STEP 2 — Install required dependencies
```bash
sudo apt-get install -y \
  apt-transport-https \
  ca-certificates \
  gnupg \
  curl
```

STEP 3 — Add Google Cloud SDK GPG key
```bash
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
| sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
```

STEP 4 — Add Google Cloud SDK repository
```bash
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] \
https://packages.cloud.google.com/apt cloud-sdk main" \
| sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
```

STEP 5 — Install Google Cloud SDK
```bash
sudo apt-get update
sudo apt-get install -y google-cloud-cli
```

STEP 6 — Verify installation
```bash
gcloud --version
```

You should see output like: `Google Cloud SDK 4xx.x.x`

STEP 7 — Authenticate (required)
```bash
gcloud auth login
```
Browser opens → log in → return to terminal.

STEP 8 — Set project
```bash
gcloud config set project [YOUR_PROJECT_ID]
```


✅ Happy learning !!!