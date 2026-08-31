set default-list
set default-script
set no-exit-message
set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']

bootstrap_dir := justfile_dir() + '/bootstrap'
kubernetes_dir := justfile_dir() + '/kubernetes'
controller := `talosctl config info --output json | jq --raw-output '.endpoints[]' | shuf -n 1`
nodes := 'uiharu miri sakura'

[private]
default: kubernetes wait namespaces resources crds apps kubeconfig

[doc('Install Talos')]
talos:
  just log info "Running stage..." "stage" "$0"
  for n in {{ nodes }}; do \
    if ! op=$(just talos::apply-node "$n" --insecure 2>&1); then \
      if [[ "$op" == *"certificate required"* ]]; then \
        just log info "Talos already configured, skipping apply of config" "stage" "$0" "node" "$n"; \
        continue; \
      fi; \
      just log fatal "Failed to apply Talos configuration" "stage" "$0" "node" "$n" "output" "$op"; \
    fi; \
  done

[doc('Install Kubernetes')]
kubernetes:
  just log info "Running stage..." "stage" "$0"
  until op=$(talosctl -n "{{ controller }}" bootstrap 2>&1 || true) && [[ "$op" == *"AlreadyExists"* ]]; do \
    just log info "Kubernetes bootstrap in progress. Retrying in 5 seconds..." "stage" "$0"; \
    sleep 5; \
  done

[doc('Fetch kubeconfig')]
kubeconfig lb="cilium":
  just log info "Running stage..." "stage" "$0"
  if ! talosctl kubeconfig -n "{{ controller }}" -f --force-context-name home-ops {{ justfile_dir() }}; then \
    just log fatal "Failed to fetch kubeconfig" "stage" "$0"; \
  fi
  if [[ "{{ lb }}" != "cilium" ]]; then \
    if ! kubectl config set-cluster home-ops --server "https://{{ controller }}:6443"; then \
      just log fatal "Failed to set kubectl cluster server address" "stage" "$0"; \
    fi; \
  fi

[doc('Wait for nodes to be not-ready')]
wait:
  just log info "Running stage..." "stage" "$0"
  if ! kubectl wait nodes --for=condition=Ready=True --all --timeout=10s &>/dev/null; then \
    until kubectl wait nodes --for=condition=Ready=False --all --timeout=10s &>/dev/null; do \
      just log info "Nodes not available, waiting for nodes to be available. Retrying in 5 seconds..." "stage" "$0"; \
      sleep 5; \
    done \
  fi

[private]
base: api-ready nodes-ready
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    if ! kustomize build {{ source_directory() }}/kustomize/personal | just template - | kubectl apply --server-side --force-conflicts -f -; then
        just log fatal "Failed to apply personal manifests" "stage" "{{ recipe_name() }}"
    fi
    if ! helmfile -f "{{ source_directory() }}/helmfile/crds.yaml" template -q | yq ea -r -e 'select(.kind == "CustomResourceDefinition")' | kubectl apply --server-side --force-conflicts -f -; then
        just log fatal "Failed to apply base crds" "stage" "{{ recipe_name() }}"
    fi

[private]
apps:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    if ! helmfile -f "{{ source_directory() }}/helmfile/apps.yaml" sync --hide-notes; then
        just log fatal "Failed to sync helmfile" "stage" "{{ recipe_name() }}"
    fi

# Wait until every apiserver answers /readyz. Helm and kubectl calls after this stage are not retried.
[private]
api-ready:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    for n in {{ nodes }}; do
        until [[ "$(curl -ks -o /dev/null -w '%{http_code}' --connect-timeout 2 "https://${n}:6443/readyz")" == "200" ]]; do
            just log info "Waiting for kube-apiserver. Retrying in 5 seconds..." "stage" "{{ recipe_name() }}" "node" "$n"
            sleep 5
        done
    done

# Wait until every node registers as Ready=False. They only become Ready=True once the CNI is healthy.
[private]
nodes-ready:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    if ! kubectl wait nodes --for=condition=Ready=True --all --timeout=10s &>/dev/null; then
        until kubectl wait nodes --for=condition=Ready=False --all --timeout=10s &>/dev/null; do
            just log info "Nodes not available, waiting for nodes to be available. Retrying in 5 seconds..." "stage" "{{ recipe_name() }}"
            sleep 5
        done
    fi
