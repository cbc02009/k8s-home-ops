#!/usr/bin/env python3
"""One-shot, idempotent patch for the pinned memini plugin: per-profile
namespace pinning.

Why this exists
--------------
The hermes gateway multiplexes every profile through one process
(config: gateway.multiplex_profiles: true), and the framework deliberately
does not load a routed profile's .env into os.environ (credential isolation).
The pinned plugin (eleboucher/memini-hermes @ MEMINI_PLUGIN_REF) resolves its
memory namespace from the process environment only, so every profile in that
process lands in the same namespace — the shared "hermes" catch-all, i.e.
every bot's memories intermixed.

What the patch does
-------------------
It adds one rung on top of the plugin's existing resolution order
(MEMINI_NAMESPACE > handshake > local git/cwd derivation): a static,
non-secret env var named MEMINI_NAMESPACE_<PROFILE> (set in the hermes
HelmRelease container env, one per profile, keyed by upper-cased profile
name) wins when the session's agent_identity matches that profile. The
generic MEMINI_NAMESPACE stays the fallback, so a pod without the pins
behaves exactly as it does today (shared namespace), and a profile without a
pin keeps the generic value.

Ops notes
---------
- The hermes HelmRelease init container runs this file (fetched from this
  repo) after the upstream plugin fetch on every pod start.
- It is a no-op when the marker comment is already present in the plugin,
  and it refuses to touch the file (warning on stderr only) when the
  upstream anchor moved — a pin bump refetches the upstream file and then
  re-applies this same reviewed patch automatically.
- Nothing here is a secret: the pins are namespace names, and the only
  server-side secret involved (MEMINI_API_KEY) already ships via the
  memini-api-keys ExternalSecret.

Run:  python3 memini-per-profile-namespace.py [path-to-plugin-__init__.py]
"""
from __future__ import annotations

import sys

DEFAULT_PATH = "/opt/data/plugins/memini/__init__.py"

MARKER = "# in-repo patch: per-profile namespace pin"

ANCHOR = """        ns, source = _resolve_namespace(self._cwd, hs)
        self._namespace = ns or "hermes"
        self._namespace_source = source if ns else "local-default"
"""

PATCH = ANCHOR + """
        # in-repo patch: per-profile namespace pin. See the docstring of
        # kubernetes/apps/llm/hermes/app/memini-per-profile-namespace.py in
        # k8s-home-ops: a multiplexed gateway serves every profile from one
        # process and a routed profile's .env is not loaded into os.environ,
        # so the pin arrives as a static env var named
        # MEMINI_NAMESPACE_<PROFILE>. It wins over the generic pin for that
        # profile only; the X-Memini-Home leg is unaffected.
        _pp_agent = str(kwargs.get("agent_identity") or "").strip()
        if _pp_agent:
            _pp_key = "MEMINI_NAMESPACE_" + _pp_agent.upper().replace("-", "_").replace("/", "_")
            _pp_pin = _env(_pp_key)
            if _pp_pin:
                self._namespace = _pp_pin
                self._namespace_source = "env:per-profile"
"""


def main() -> int:
    path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_PATH
    try:
        with open(path, encoding="utf-8") as fh:
            src = fh.read()
    except OSError as exc:
        print(f"WARN: per-profile namespace patch: cannot read {path}: {exc}")
        return 0
    if MARKER in src:
        return 0
    if ANCHOR not in src:
        print(
            "WARN: per-profile namespace patch: upstream anchor not found "
            "(the pinned plugin file changed); leaving the plugin unpatched"
        )
        return 0
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(src.replace(ANCHOR, PATCH, 1))
    print(f"per-profile namespace patch applied to {path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
