# node-power-tuner

Reduces the idle power draw of the dGPU worker node (**mayne**) — the box whose
outlet meter averages ~229 W and whose GPU is only ~9% utilized over a month,
so most of its electricity is the platform (CPU, PCIe, memory) sitting at
"high idle" rather than doing useful work.

## What it does

One privileged DaemonSet pinned to the `topology.kubernetes.io=dgpu` node.
Every 30 s it re-asserts three host `/sys` settings (idempotently — it only
writes when the value differs, so it stays quiet):

| # | Lever | Setting | Applies to |
|---|-------|---------|------------|
| 1 | CPU frequency governor | `schedutil` | all CPUs |
| 1 | AMD CPPC EPP (`energy_performance_preference`) | `balance_power` | all CPUs (only if the file exists, i.e. `amd_pstate` in EPP mode) |
| 2 | PCIe link ASPM (`link/aspm`) | `powersave` | every non-GPU PCI device (NVMe, Mellanox NIC, USB) |
| 3 | PCI runtime power management (`power/control`) | `auto` | every non-GPU PCI device |

It mounts the host `/sys` read-write at `/host/sys` (the `hostPath` pattern used
by the other privileged node DaemonSets in this repo, though those mount it
read-only — this one needs write access to persist the settings) and targets that
path, so it is unambiguous about touching the host, not a container-namespaced sysfs.

**Deliberately skipped:** the NVIDIA 4090 (`vendor 0x10de`). It holds the
always-resident `qwen3.8-27b` model, so a live CUDA context is present at all
times — putting it into runtime-PM could evict the model, and its PCIe link is
continuously active, so lowering its ASPM buys nothing. The GPU is left
entirely to the existing `nvidia-power-limit` DaemonSet (350 W cap).

No kernel arguments and no Talos re-image are required: everything is a
runtime sysfs write, so the change takes effect the moment the pod starts
(≈1–2 min after the PR merges) with no node reboot.

## Expected impact

A few-to-few-tens of watts off the idle floor (governor + EPP are the main
win; ASPM and runtime-PM are smaller but free). Verify against the outlet
meter, not by trusting the sysfs writes (see below).

## Verification

```bash
# GPU left alone, everything else tuned (read from the node, e.g. via the pod):
cat  /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor          # schedutil
cat  /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference # balance_power
cat  /sys/bus/pci/devices/<nvme>/power/control                     # auto
cat  /sys/bus/pci/devices/<nvme>/link/aspm                        # powersave
cat  /sys/bus/pci/devices/0000:04:00.0/power/control              # on (GPU, unchanged)

# pod logs show each change as it is first applied (then silence):
kubectl -n kube-system logs -l app=node-power-tuner --tail=50
```

## Measuring the win (do this, not the sysfs reads)

The only number that matters is the PDU outlet meter for mayne
(`unpoller_device_outlet_outlet_power{instance="10.11.0.207:9130",outlet_index="9"}`).
Baseline it for ~24 h **before** merging, then again **after**, and compare the
average. At $0.30/kWh, even 20 W off a 229 W floor is ~$4/month.

## Tuning knobs

- **More aggressive EPP:** change `balance_power` → `power` in the script for
  maximum CPU power savings at the cost of a little latency headroom.
- **GPU PCIe link ASPM:** to also lower the 4090's link ASPM, widen the
  `NVIDIA_VENDOR` guard so it no longer skips the `link/aspm` branch. Note the
  ASPM and runtime-PM branches share a single per-device `continue`, so this is a
  small condition restructure, not a one-line delete. Low risk, low reward.
- **Broaden cluster-wide:** drop the `nodeSelector`/`tolerations` in
  `helmrelease.yaml` and the pod runs on every node instead of just the dGPU
  box.

## Rollback

Delete the app (Flux prunes it) — or, non-destructively, comment out the
`./node-power-tuner/ks.yaml` line in `kubernetes/apps/kube-system/kustomization.yaml`.
Important: stopping the loop does **not** restore stock settings — the `/sys` values
it wrote (governor, EPP, PCIe ASPM, PCI runtime-PM) **persist** on the node until the
next reboot, or until you explicitly re-write the stock values. Deleting the
DaemonSet therefore only *stops future changes*; it is not itself a restore.
