#!/usr/bin/env bash

# Deploy the configuration to the nodes
talosctl apply-config -i -n 10.0.2.5 -e 10.0.2.5 -f ./clusterconfig/dns-rem.ctec.run.yaml
