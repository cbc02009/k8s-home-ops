#!/usr/bin/env bash

# Deploy the configuration to the nodes
talosctl apply-config -n 10.0.2.10 -e 10.0.2.10 -f ./clusterconfig/cluster-uiharu.ctec.run.yaml
talosctl apply-config -n 10.0.2.12 -e 10.0.2.12 -f ./clusterconfig/cluster-sakura.ctec.run.yaml
talosctl apply-config -n 10.0.2.15 -e 10.0.2.15 -f ./clusterconfig/cluster-miri.ctec.run.yaml
