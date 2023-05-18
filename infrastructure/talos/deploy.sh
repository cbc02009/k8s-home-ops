#!/bin/bash

# Only need to do this once since the config keys will always be the same
# talosctl --talosconfig=./clusterconfig/talosconfig config endpoint 10.11.0.16 10.11.0.17 10.11.0.18
# talosctl config merge ./clusterconfig/talosconfig
# talosctl kubeconfig -n 10.11.0.16

# Deploy the configuration to the nodes
talosctl apply-config -i -n uiharu.ctec.run -f ./clusterconfig/kokoro-uiharu.ctec.run.yaml
talosctl apply-config -i -n sakura.ctec.run -f ./clusterconfig/kokoro-sakura.ctec.run.yaml
talosctl apply-config -i -n anya.ctec.run -f ./clusterconfig/kokoro-anya.ctec.run.yaml
talosctl apply-config -i -n rem.ctec.run -f ./clusterconfig/kokoro-rem.ctec.run.yaml
talosctl apply-config -i -n ram.ctec.run -f ./clusterconfig/kokoro-ram.ctec.run.yaml

# It will take a few minutes for the nodes to spin up with the configuration.  Once ready, execute
# talosctl bootstrap -n k8s-1
# ./deploy-cni.sh
