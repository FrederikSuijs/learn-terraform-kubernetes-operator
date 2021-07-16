terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      #version = "2.0.2"
    }
  }
}

variable "host" {
  type = string
}

variable "client_certificate" {
  type = string
}

variable "client_key" {
  type = string
}

variable "cluster_ca_certificate" {
  type = string
}

variable "aci_username" {
  type = string
}

variable "aci_password" {
  type = string
}

provider "kubernetes" {
  host = var.host

  client_certificate     = base64decode(var.client_certificate)
  client_key             = base64decode(var.client_key)
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
}

// Create namespace for Operator
resource "kubernetes_namespace" "edu" {
  metadata {
    name = "edu"
  }
}

// Create terraformrc secret for Operator
resource "kubernetes_secret" "terraformrc" {
  metadata {
    name      = "terraformrc"
    namespace = kubernetes_namespace.edu.metadata[0].name
  }

  data = {
    "credentials" = file("${path.cwd}/credentials")
  }
}

// Create workspace secret for Operator
resource "kubernetes_secret" "workspacesecrets" {
  metadata {
    name      = "workspacesecrets"
    namespace = kubernetes_namespace.edu.metadata[0].name
  }

  data = {
    "ACI_USERNAME" = var.aci_username
    "ACI_PASSWORD" = var.aci_password
  }
}

provider "helm" {
  kubernetes {
    host = var.host

    client_certificate     = base64decode(var.client_certificate)
    client_key             = base64decode(var.client_key)
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  }
}

// Terraform Cloud Operator for Kubernetes helm chart
resource "helm_release" "operator" {
  name       = "terraform-operator"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "terraform"

  namespace = kubernetes_namespace.edu.metadata[0].name

  depends_on = [
    kubernetes_secret.terraformrc,
    kubernetes_secret.workspacesecrets
  ]
}
