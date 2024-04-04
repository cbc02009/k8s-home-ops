#!/usr/bin/env bash

# Deploy the configuration to the nodes
talosctl apply-config -n 10.0.2.10 -e 10.0.2.10 -f ./clusterconfig/main-uiharu.ctec.run.yaml
talosctl apply-config -n 10.0.2.12 -e 10.0.2.12 -f ./clusterconfig/main-sakura.ctec.run.yaml
talosctl apply-config -n 10.0.2.11 -e 10.0.2.11 -f ./clusterconfig/main-miri.ctec.run.yaml
