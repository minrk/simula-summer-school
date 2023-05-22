terraform {
  backend "gcs" {
    # make bucket by hand first
    # https://console.cloud.google.com/storage/browser
    bucket = "tf-state-simber-workshop-may2023"
    prefix = "terraform/state"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.63.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.9.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.20.0"
    }
  }
}
data "google_client_config" "provider" {}

provider "google" {
  project = "simber-workshop-may2023"
  region  = "europe-north1"
  zone    = "europe-north1-b"
}

locals {
  gke_version  = "1.24.11-gke.1000"
  cluster_name = "simber"
  location     = data.google_client_config.provider.region # regional cluster
  # region       = data.google_client_config.provider.region
  zone = data.google_client_config.provider.zone

}

resource "google_artifact_registry_repository" "repo" {
  location      = local.location
  repository_id = "sss"
  description   = "summer school container registry"
  format        = "DOCKER"
}

resource "google_container_cluster" "cluster" {
  name     = local.cluster_name
  location = local.location

  min_master_version = local.gke_version

  # terraform recommends removing the default node pool
  remove_default_node_pool = true
  initial_node_count       = 1

  maintenance_policy {
    # times are UTC
    # allow maintenance only on weekends,
    # from late Western Friday night (10pm Honolulu UTC-10)
    # to early Eastern Monday AM (4am Sydney UTC+11)
    recurring_window {
      start_time = "2021-01-02T08:00:00Z"
      end_time   = "2021-01-03T17:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SA"
    }
  }

  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  addons_config {
    network_policy_config {
      disabled = false
    }
  }
}

# define node pools here, too hard to encode with variables
resource "google_container_node_pool" "core" {
  name     = "core-202304"
  cluster  = google_container_cluster.cluster.name
  location = local.location # location of *cluster*
  # node_locations lets us specify a single-zone regional cluster:
  node_locations = [local.zone]

  lifecycle {
    ignore_changes = [node_count]
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 1
  }
  node_count = 1
  version    = local.gke_version

  node_config {
    machine_type = "e2-standard-4"
    disk_size_gb = 100
    disk_type    = "pd-balanced"

    labels = {
      "hub.jupyter.org/node-purpose" = "core"
    }
    # https://www.terraform.io/docs/providers/google/r/container_cluster.html#oauth_scopes-1
    oauth_scopes = [
      "storage-ro",
      "logging-write",
      "monitoring",
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

resource "google_container_node_pool" "user" {
  name     = "user-202304"
  cluster  = google_container_cluster.cluster.name
  location = local.location # location of *cluster*
  # node_locations lets us specify a single-zone regional cluster:
  node_locations = [local.zone]
  version        = local.gke_version

  lifecycle {
    ignore_changes = [node_count]
  }

  autoscaling {
    min_node_count = 0
    max_node_count = 8
  }


  node_config {
    machine_type = "e2-standard-8"
    disk_size_gb = 100
    disk_type    = "pd-balanced"

    labels = {
      "hub.jupyter.org/node-purpose" = "user"
    }
    # https://www.terraform.io/docs/providers/google/r/container_cluster.html#oauth_scopes-1
    oauth_scopes = [
      "storage-ro",
      "logging-write",
      "monitoring",
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

output "cluster_name" {
  value = google_container_cluster.cluster.name
}

provider "kubernetes" {
  host  = "https://${google_container_cluster.cluster.endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(
    google_container_cluster.cluster.master_auth[0].cluster_ca_certificate,
  )
  # FIXME:
  # config_path    = "~/.kube/config"
  # config_context = "sss"
}

resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = "cert-manager"
  }
  depends_on = [google_container_cluster.cluster]
}

resource "kubernetes_namespace" "hub" {
  metadata {
    name = "jupyterhub"
  }
  depends_on = [google_container_cluster.cluster]
}

provider "helm" {

  kubernetes {
    config_path    = "~/.kube/config"
    config_context = local.cluster_name
  }
}

module "cert-manager" {
  source        = "basisai/cert-manager/helm"
  version       = "0.1.3"
  chart_version = "1.11.0"

  chart_namespace = "cert-manager"
  depends_on      = [kubernetes_namespace.cert-manager]
  ingress_shim = {
    defaultIssuerName = "letsencrypt-prod"
    defaultIssuerKind = "ClusterIssuer"
  }
}
