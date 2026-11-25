# terraform/mikrotik — RouterOS switches (OpenTofu)

Manages the four RouterOS switches as code via [`ebogdum/routeros`](https://registry.terraform.io/providers/ebogdum/routeros/latest/docs) (REST API, min RouterOS 7.1 — fleet runs 7.25.2).

| router key | device | model | mgmt |
|---|---|---|---|
| `backbone` | backbone-switch | CRS317-1G-16S+ | https://10.0.0.2 |
| `office` | office-switch | CRS305-1G-4S+ | http://10.0.0.4 |
| `media` | media-switch | CRS305-1G-4S+ | http://10.0.0.6 |
| `cluster` | cluster-switch | CRS310-8G+2S+ | http://10.0.0.7 |

**Out of scope:** `1gb-switch` (CSS326) and `workbench-switch` (CSS106) are SwOS-only devices — the REST provider cannot reach them and SwOS has a single admin account. They remain MikroMCP-managed (read-only) until a RouterOS-capable replacement or a deliberate SwOS write path exists.

## Scope

Per device: the bridge, its VLAN entries, bridge ports, interface lists + members, and non-dynamic IP addresses — generated from live MikroMCP inventory. All resources live in `modules/switch/` (one module call per device in `<router>.tofu`), so per-device files contain only data: names, VLAN ids, tagged/untagged port lists. Import with `sh imports.sh` (module-scoped addresses, live `.id`s).

Not managed (not present on these devices): DHCP, firewall, routes, WireGuard, DNS entries.

## Safety model

- **No `tofu apply` without a reviewed plan.** The fleet is production L2; bridge/VLAN changes can take the network down.
- **Lockout guards** in the provider cover user/firewall changes; we manage neither, but bridge changes can still strand access — always check which ports carry management.
- Credentials come from environment variables (`TF_VAR_backbone_user`, ...). Never in git, never in `.tofu` files. Prefer a dedicated **read/write API user per device** (RouterOS lets you scope one) over the admin account.
- State is local and gitignored. **Never commit `terraform.tfstate`, `.terraform/`, or plan files.**

## Running it

```sh
cd terraform/mikrotik
# direnv exports ROUTEROS_* / TF_VAR_* via ../secrets.sops.yaml
tofu init
tofu plan        # expect "N to import, 0 to add, 0 to change" once imports are recorded
tofu apply       # only after human review
```
