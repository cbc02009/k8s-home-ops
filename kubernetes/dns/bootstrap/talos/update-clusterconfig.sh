#!/usr/bin/env bash

# Deploy the configuration to the nodes
# talosctl apply-config --context dns -n 10.0.2.5 -e 10.0.2.5 -f ./clusterconfig/dns-rem.ctec.run.yaml
# talosctl apply-config --context dns -n 10.0.2.6 -e 10.0.2.6 -f ./clusterconfig/dns-ram.ctec.run.yaml
talosctl apply-config --context dns -n 10.0.2.13 -e 10.0.2.13 -f ./clusterconfig/dns-anya.ctec.run.yaml
