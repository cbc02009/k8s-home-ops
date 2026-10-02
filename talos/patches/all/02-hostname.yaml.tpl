---
# topf only uses nodes[].host for display and selection; without this Talos
# would fall back to auto: stable and come up as talos-xxx-xxx.
apiVersion: v1alpha1
kind: HostnameConfig
auto: "off"
hostname: {{ .Node.Host }}
