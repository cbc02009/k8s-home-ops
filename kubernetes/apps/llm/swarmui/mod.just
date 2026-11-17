set default-list
set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

[doc('Take the dGPU for image generation: suspend Flux, scale SwarmUI to 1, preempt the LLM pod, block until Ready')]
up:
  flux suspend helmrelease swarmui -n llm
  kubectl scale deployment swarmui -n llm --replicas=1
  kubectl rollout status deployment swarmui -n llm

[doc('Hand the dGPU back: scale SwarmUI to 0, let the LLM pod rebind, resume Flux')]
down:
  kubectl scale deployment swarmui -n llm --replicas=0
  flux resume helmrelease swarmui -n llm
