# Private GKE Cluster with Terraform

This repository creates a private Google Kubernetes Engine cluster on GCP using Terraform.

It provisions:

- Custom VPC and subnet
- Secondary IP ranges for GKE pods and services
- Cloud Router and Cloud NAT
- Bastion VM
- Private GKE cluster
- GKE node pool


```bash
gcloud --version
terraform version
```

## 1. Authenticate with GCP

Login to Google Cloud:

```bash
gcloud auth login
```

Create application default credentials for Terraform:

```bash
gcloud auth application-default login
```
```bash
gcloud auth application-default set-quota-project playground-s-11-2b402bd1
```

## 2. Enable Required GCP APIs

Run these commands once for your project:

```bash
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
```

## 3. Update Terraform Variables

Edit `terraform.tfvars` and set your project, region, and zone:

```hcl
project_id = "your-gcp-project-id"
region     = "us-central1"
zone       = "us-central1-a"
```

## 4. Run Terraform

Initialize Terraform:

```bash
terraform init
```

Review the resources Terraform will create:

```bash
terraform plan
```

Create the infrastructure:

```bash
terraform apply
```

When prompted, type:

```text
yes
```

## 5. Connect to the Bastion VM

After Terraform completes, connect to the bastion VM from the GCP Console or with:

## 6. Configure gcloud on Bastion

On the bastion VM, verify the tools and install 
```
apt update -y
sudo apt install -y google-cloud-cli
sudo apt install -y google-cloud-sdk-gke-gcloud-auth-plugin
sudo apt install git -y
sudo apt-get install kubectl
```

```bash
gcloud --version
kubectl version --client
```

Log in if required:

```bash
gcloud auth login
```

Set the project:

```bash
gcloud config set project <PROJECT_ID>
```

Set the compute zone:

```bash
gcloud config set compute/zone us-central1-a
```

## 7. Get GKE Cluster Credentials

The Terraform cluster name is `murthy`.

Run this from the bastion VM:

```bash
gcloud container clusters get-credentials murthy --location us-central1-a
```

Verify access:

```bash
kubectl get nodes
```

## 8. Deploy a LoadBalancer Service

If you have a Kubernetes service manifest, apply it from the bastion VM:

```bash
kubectl apply -f loadbalancer-service.yaml
```

Check the external IP:

```bash
kubectl get svc
```

Use the `EXTERNAL-IP` value to access the application.

Note: `loadbalancer-service.yaml` is referenced here only if you add that file to this repo or copy it to the bastion VM.

## 9. Destroy the Infrastructure

To delete everything created by Terraform, run this from your local machine:

```bash
terraform destroy
```

When prompted, type:

```text
yes
```
