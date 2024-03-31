#!/usr/bin/env bash

# Deploy the configuration to the nodes
talosctl apply-config -i -n 10.0.7.10 -e 10.0.7.10 -f ./clusterconfig/dns-ivy.ctec.run.yaml
