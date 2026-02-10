#!/usr/bin/env -S just --justfile

set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

mod k8s-bootstrap "kubernetes/bootstrap"
mod k8s "kubernetes"
mod talos "kubernetes/talos"
# mod nas "nas"
# mod nas-talos "nas/talos"
# mod nas-bootstrap "nas/bootstrap"

[private]
default:
  just -l

[private]
log lvl msg *args:
  gum log -t rfc3339 -s -l "{{ lvl }}" "{{ msg }}" {{ args }}

[private]
template file *args:
  minijinja-cli "{{ file }}" {{ args }} | op inject

# [private]
# ekubectl cluster *args:
#   if cluster == 'nas' {
#     KUBECONFIG=justfile_dir()+'/nas/kubeconfig' kubectl {{ args }}
#   } else {
#     KUBECONFIG=justfile_dir()+'/kubernetes/kubeconfig' kubectl {{ args }}
#   }

# [private]
# etalosctl cluster *args:
#   if cluster == 'nas' {
#   TALOSCONFIG=justfile_dir()+'/nas/talos/talosconfig' talosctl {{ args }}
#   } else {
#   TALOSCONFIG=justfile_dir()+'/kubernetes/talos/clusterconfig/talosconfig' talosctl {{ args }}
#   }
