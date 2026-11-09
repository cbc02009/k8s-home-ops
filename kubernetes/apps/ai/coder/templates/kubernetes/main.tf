terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

provider "coder" {
}

variable "use_kubeconfig" {
  type        = bool
  description = <<-EOF
  Use host kubeconfig? (true/false)

  Set this to false if the Coder host is itself running as a Pod on the same
  Kubernetes cluster as you are deploying workspaces to.

  Set this to true if the Coder host is running outside the Kubernetes cluster
  for workspaces.  A valid "~/.kube/config" must be present on the Coder host.
  EOF
  default     = false
}

variable "namespace" {
  type        = string
  description = "The Kubernetes namespace to create workspaces in (must exist prior to creating workspaces). If the Coder host is itself running as a Pod on the same Kubernetes cluster as you are deploying workspaces to, set this to the same namespace."
  default     = "ai"
}

variable "storage_class" {
  type        = string
  description = "Storage class used for the home volume."
  default     = "ceph-filesystem"
}

data "coder_parameter" "cpu" {
  name         = "cpu"
  display_name = "CPU"
  description  = "The number of CPU cores"
  default      = "2"
  icon         = "/icon/memory.svg"
  mutable      = true
  option {
    name  = "2 Cores"
    value = "2"
  }
  option {
    name  = "4 Cores"
    value = "4"
  }
  option {
    name  = "6 Cores"
    value = "6"
  }
  option {
    name  = "8 Cores"
    value = "8"
  }
}

data "coder_parameter" "memory" {
  name         = "memory"
  display_name = "Memory"
  description  = "The amount of memory in GB"
  default      = "2"
  icon         = "/icon/memory.svg"
  mutable      = true
  option {
    name  = "2 GB"
    value = "2"
  }
  option {
    name  = "4 GB"
    value = "4"
  }
  option {
    name  = "6 GB"
    value = "6"
  }
  option {
    name  = "8 GB"
    value = "8"
  }
}

data "coder_parameter" "home_disk_size" {
  name         = "home_disk_size"
  display_name = "Home disk size"
  description  = "The size of the home disk in GB"
  default      = "10"
  type         = "number"
  icon         = "/emojis/1f4be.png"
  mutable      = false
  validation {
    min = 1
    max = 99999
  }
}

provider "kubernetes" {
  # In-cluster: the Coder server runs in this cluster, so the provisioner
  # authenticates with the chart's service account (workspacePerms, default
  # on) rather than a kubeconfig.
  config_path = var.use_kubeconfig == true ? "~/.kube/config" : null
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

resource "coder_agent" "main" {
  os             = "linux"
  arch           = "amd64"
  startup_script = <<-EOT
    set -e

    # --- Secrets (pod-mounted, see kubernetes_deployment_v1 below) ---
    #   /run/secrets/litellm  <- Secret litellm-key-coder  (LiteLLM virtual key "Coder")
    #   /run/secrets/memini   <- Secret memini-key-opencode ("opencode" memini key)
    export LITELLM_API_KEY="$(cat /run/secrets/litellm/api-key)"
    export MEMINI_API_KEY="$(cat /run/secrets/memini/api-key)"

    # Make the keys (and the opencode bin dir) available to future login shells.
    {
      echo 'export PATH="$HOME/.opencode/bin:$PATH"'
      echo 'export LITELLM_API_KEY="$(cat /run/secrets/litellm/api-key)"'
      echo 'export MEMINI_API_KEY="$(cat /run/secrets/memini/api-key)"'
    } > /etc/profile.d/coder-secrets.sh
    chmod 0644 /etc/profile.d/coder-secrets.sh

    # --- opencode (OpenCode 2, standalone binary; reinstalled on every start
    # to pick up the latest release, the binary lives on the persistent home) ---
    export PATH="$HOME/.opencode/bin:$PATH"
    curl -fsSL https://opencode.ai/v2/install | bash

    # opencode config - mirrors the cluster opencode agent with in-cluster
    # endpoints and the mounted keys.
    mkdir -p "$HOME/.config/opencode"
    cat > "$HOME/.config/opencode/opencode.json" <<'JSON'
    {
      "$schema": "https://opencode.ai/config.json",
      "compaction": {
        "auto": true,
        "buffer": 16384,
        "keep": {
          "tokens": 20000
        }
      },
      "enabled_providers": [
        "litellm",
        "opencode"
      ],
      "model": "litellm/qwen3.8-27b",
      "permission": "allow",
      "plugins": [
        {
          "options": {
            "auto_update": false,
            "base_url": "http://memini.ai.svc.cluster.local",
            "namespace": "opencode"
          },
          "package": "@eleboucher/opencode-memini-v2@0.7.38"
        }
      ],
      "provider": {
        "litellm": {
          "models": {
            "free-pool": {
              "limit": {
                "context": 200000,
                "output": 16384
              },
              "name": "Free Pool (public work only)"
            },
            "implementation-pool": {
              "limit": {
                "context": 147456,
                "output": 16384
              },
              "name": "Implementation Pool"
            },
            "muse-glimmer": {
              "limit": {
                "context": 131072,
                "output": 20480
              },
              "name": "Muse Glimmer 30B"
            },
            "qwen3.8-27b": {
              "limit": {
                "context": 147456,
                "output": 24576
              },
              "name": "Qwen3.8-27B W4A16"
            },
            "qwen3.8-27b-chat": {
              "limit": {
                "context": 147456,
                "output": 16384
              },
              "name": "Qwen3.8-27B W4A16 non-thinking"
            }
          },
          "name": "LiteLLM OpenAI",
          "npm": "@ai-sdk/openai-compatible",
          "options": {
            "apiKey": "{env:LITELLM_API_KEY}",
            "baseURL": "http://litellm.ai.svc.cluster.local:4000/v1",
            "timeout": 1800000
          }
        }
      },
      "tool_output": {
        "max_bytes": 16384,
        "max_lines": 800
      },
      "mcp": {
        "servers": {
          "toolhive": {
            "type": "remote",
            "url": "http://vmcp-mcp-gateway-internal.ai.svc.cluster.local:4483"
          }
        }
      }
    }
    JSON

    # --- code-server ---
    curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/tmp/code-server

    # Start code-server in the background.
    /tmp/code-server/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &
  EOT

  # The following metadata blocks are optional. They are used to display
  # information about your workspace in the dashboard. You can remove them
  # if you don't want to display any information.
  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Home Disk"
    key          = "3_home_disk"
    script       = "coder stat disk --path $${HOME}"
    interval     = 60
    timeout      = 1
  }

  metadata {
    display_name = "CPU Usage (Host)"
    key          = "4_cpu_usage_host"
    script       = "coder stat cpu --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Memory Usage (Host)"
    key          = "5_mem_usage_host"
    script       = "coder stat mem --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Load Average (Host)"
    key          = "6_load_host"
    # get load avg scaled by number of cores
    script   = <<EOT
      echo "`cat /proc/loadavg | awk '{ print $1 }'` `nproc`" | awk '{ printf "%0.2f", $1/$2 }'
    EOT
    interval = 60
    timeout  = 1
  }
}

# code-server
resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "code-server"
  icon         = "/icon/code.svg"
  url          = "http://localhost:13337?folder=/home/coder"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 3
    threshold = 10
  }
}

resource "kubernetes_persistent_volume_claim_v1" "home" {
  metadata {
    name      = "coder-${data.coder_workspace.me.id}-home"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"     = "coder-pvc"
      "app.kubernetes.io/instance" = "coder-pvc-${data.coder_workspace.me.id}"
      "app.kubernetes.io/part-of"  = "coder"
      //Coder-specific labels.
      "com.coder.resource"       = "true"
      "com.coder.workspace.id"   = data.coder_workspace.me.id
      "com.coder.workspace.name" = data.coder_workspace.me.name
      "com.coder.user.id"        = data.coder_workspace_owner.me.id
      "com.coder.user.username"  = data.coder_workspace_owner.me.name
    }
    annotations = {
      "com.coder.user.email" = data.coder_workspace_owner.me.email
    }
  }
  wait_until_bound = false
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.storage_class
    resources {
      requests = {
        storage = "${data.coder_parameter.home_disk_size.value}Gi"
      }
    }
  }
}

resource "kubernetes_deployment_v1" "main" {
  count = data.coder_workspace.me.start_count
  depends_on = [
    kubernetes_persistent_volume_claim_v1.home
  ]
  wait_for_rollout = false
  metadata {
    name      = "coder-${data.coder_workspace.me.id}"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"     = "coder-workspace"
      "app.kubernetes.io/instance" = "coder-workspace-${data.coder_workspace.me.id}"
      "app.kubernetes.io/part-of"  = "coder"
      "com.coder.resource"         = "true"
      "com.coder.workspace.id"     = data.coder_workspace.me.id
      "com.coder.workspace.name"   = data.coder_workspace.me.name
      "com.coder.user.id"          = data.coder_workspace_owner.me.id
      "com.coder.user.username"    = data.coder_workspace_owner.me.name
    }
    annotations = {
      "com.coder.user.email" = data.coder_workspace_owner.me.email
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name"     = "coder-workspace"
        "app.kubernetes.io/instance" = "coder-workspace-${data.coder_workspace.me.id}"
        "app.kubernetes.io/part-of"  = "coder"
        "com.coder.resource"         = "true"
        "com.coder.workspace.id"     = data.coder_workspace.me.id
        "com.coder.workspace.name"   = data.coder_workspace.me.name
        "com.coder.user.id"          = data.coder_workspace_owner.me.id
        "com.coder.user.username"    = data.coder_workspace_owner.me.name
      }
    }
    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"     = "coder-workspace"
          "app.kubernetes.io/instance" = "coder-workspace-${data.coder_workspace.me.id}"
          "app.kubernetes.io/part-of"  = "coder"
          "com.coder.resource"         = "true"
          "com.coder.workspace.id"     = data.coder_workspace.me.id
          "com.coder.workspace.name"   = data.coder_workspace.me.name
          "com.coder.user.id"          = data.coder_workspace_owner.me.id
          "com.coder.user.username"    = data.coder_workspace_owner.me.name
        }
      }
      spec {
        # Only allowed to read the two API key Secrets (see rbac.yaml in the
        # coder app); the template mounts them at /run/secrets.
        service_account_name = "coder-workspace"

        security_context {
          run_as_user     = 1000
          fs_group        = 1000
          run_as_non_root = true
        }

        container {
          name              = "dev"
          image             = "codercom/example-base:ubuntu"
          image_pull_policy = "Always"
          command           = ["sh", "-c", coder_agent.main.init_script]
          security_context {
            run_as_user = "1000"
          }
          env {
            name  = "CODER_AGENT_TOKEN"
            value = coder_agent.main.token
          }
          resources {
            requests = {
              "cpu"    = "250m"
              "memory" = "512Mi"
            }
            limits = {
              "cpu"    = "${data.coder_parameter.cpu.value}"
              "memory" = "${data.coder_parameter.memory.value}Gi"
            }
          }
          volume_mount {
            mount_path = "/home/coder"
            name       = "home"
            read_only  = false
          }
          volume_mount {
            mount_path = "/run/secrets/litellm"
            name       = "litellm"
            read_only  = true
          }
          volume_mount {
            mount_path = "/run/secrets/memini"
            name       = "memini"
            read_only  = true
          }
        }

        volume {
          name = "home"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.home.metadata.0.name
            read_only  = false
          }
        }
        volume {
          name = "litellm"
          secret {
            secret_name = "litellm-key-coder"
          }
        }
        volume {
          name = "memini"
          secret {
            secret_name = "memini-key-opencode"
          }
        }

        affinity {
          // This affinity attempts to spread out all workspace pods evenly across
          // nodes.
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 1
              pod_affinity_term {
                topology_key = "kubernetes.io/hostname"
                label_selector {
                  match_expressions {
                    key      = "app.kubernetes.io/name"
                    operator = "In"
                    values   = ["coder-workspace"]
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
