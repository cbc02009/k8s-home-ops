set default-list
set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

[doc('Take the dGPU for ComfyUI: suspend Flux, scale ComfyUI to 1, preempt the LLM pod, block until Ready')]
up:
  flux suspend helmrelease comfyui -n llm
  kubectl scale deployment comfyui -n llm --replicas=1
  kubectl rollout status deployment comfyui -n llm

[doc('Hand the dGPU back: scale ComfyUI to 0, let the LLM pod rebind, resume Flux')]
down:
  kubectl scale deployment comfyui -n llm --replicas=0
  flux resume helmrelease comfyui -n llm
