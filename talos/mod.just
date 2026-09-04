set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

kubernetes_dir := justfile_dir() + '/kubernetes'
talos_dir := justfile_dir() + '/talos'

controller := `talosctl config info --output json | jq --raw-output '.endpoints[]' | shuf -n 1`
nodes := `talosctl config info -o yaml | yq -e '.nodes | join (",")'`

[private]
default:
  just -l talos

talhelper-genconfig *args:
  op run --env-file {{ talos_dir }}/talhelper-secrets.env --no-masking -- talhelper genconfig \
        --secret-file {{ talos_dir }}/talsecret.yaml \
        --config-file {{ talos_dir }}/talconfig.yaml \
        --out-dir {{ talos_dir }}/clusterconfig

# [doc('Apply Talos config to a node')]
# apply-node node *args:
#   just log info "Applying Talos machineconfig" "node" "{{ node }}";
#   just talos render-config "{{ node }}" | talosctl -n "{{ node }}" apply-config -f /dev/stdin {{ args }}

# [doc('Apply Talos config to all nodes in the cluster')]
# apply-cluster *args:
#   kubectl get nodes --no-headers | while read -r node _; do \
#     just talos apply-node ${node} {{ args }}; \
#   done

[doc('Apply Talos config to a node')]
apply-node node *args:
  just log info "Applying Talos machineconfig" "node" "{{ node }}";
  talosctl apply-config -n "{{ node }}" --file {{ talos_dir }}/clusterconfig/home-ops-{{ node }}.yaml {{ args }}

# [doc('Apply Talos config to all nodes in the cluster')]
# apply-cluster *args:


[doc('Generate schematic ID from Talos schematic')]
gen-schematic-id:
  curl -sX POST --data-binary "@{{ talos_dir }}/schematic.yaml" "https://factory.talos.dev/schematics" | jq -r '.id'

[doc('Render Talos config for a node')]
render-config node:
  export IS_CONTROLLER="$(just talos machine-controller {{ node }})"; \
  talosctl machineconfig patch <(just template "{{ talos_dir }}/machineconfig.yaml.j2") \
    -p @<(just template "{{ talos_dir }}/nodes/{{ node }}.yaml.j2")

[doc('Reboot a node')]
reboot-node node:
  gum confirm "Reboot node {{ node }}?" && \
    talosctl -n {{ node }} reboot -m powercycle || exit 0

[confirm('Reset node ' + node + ' [y|N] ?')]
[doc('Reset a node')]
reset-node node *args:
    talosctl -n "{{ node }}" reset --system-labels-to-wipe STATE --system-labels-to-wipe EPHEMERAL --system-labels-to-wipe u-local-hostpath --graceful=false {{ args }}

[doc('Reset all nodes in the cluster')]
reset-cluster mode="reboot":
  just talos reset-node {{ nodes }} {{ mode }};\

[confirm('Upgrade Kubernetes to ' + version + ' [y|N] ?')]
[doc('Upgrade Kubernetes version on the cluster')]
upgrade-k8s version:
    talosctl -n "$(talosctl config info -o yaml | yq -r -e '.endpoints[0]')" upgrade-k8s --to {{ version }}

[confirm('Upgrade node ' + node + ' [y|N] ?')]
[doc('Upgrade Talos version on a node')]
upgrade-node node *args:
    talosctl -n "{{ node }}" upgrade -i "$(just talos machine-image "{{ node }}")" -m powercycle --timeout=10m {{ args }}

[doc('Download Talos machine image')]
download-image version node="":
    export SCHEMATIC="$(just talos schematic-id "{{ node }}")"
    curl -fL --remove-on-error --retry 5 --retry-delay 5 --retry-all-errors --progress-bar \
        -o "{{ source_directory() }}/talos-{{ version }}-${SCHEMATIC:0:8}.iso" \
        "https://factory.talos.dev/image/${SCHEMATIC}/{{ version }}/metal-amd64.iso"
    just log info "Downloaded Talos" version "{{ version }}" schematic "${SCHEMATIC}"

# [private]
machine-controller node:
  just template "{{ talos_dir }}/nodes/{{ node }}.yaml.j2" | yq -e 'select(.machine) | (.machine.type == "controlplane") // ""'

[doc('Get the machine image for a given node')]
[private]
machine-image node:
  talosctl --nodes {{ node }} get machineconfig --output=jsonpath='{.spec}' | yq -e 'select(.machine) | .machine.install.image'
