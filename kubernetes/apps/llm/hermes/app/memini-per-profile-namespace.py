#!/usr/bin/env python3
"""One-shot, idempotent patch for the pinned memini plugin: per-profile
namespace by convention (derived from the session's agent_identity).

Why this exists
---------------
The hermes gateway multiplexes every profile through one process
(config: gateway.multiplex_profiles: true), and the framework deliberately
does not load a routed profile's .env into os.environ (credential isolation).
The pinned plugin (eleboucher/memini-hermes @ MEMINI_PLUGIN_REF) resolves its
memory namespace from the process environment only, so every profile in that
process lands in the same namespace — the shared "hermes" catch-all, i.e.
every bot's memories intermixed.

The first iteration of this patch solved that with a static env map: one
MEMINI_NAMESPACE_<PROFILE> per profile, delivered via the HelmRelease. That
only works for containers that carry the map, must be kept in sync as
profiles are added, and silently misses new ones (why the per-profile
sub-namespaces never materialized in practice). See the diagnosis in the
k8s-home-ops PR history: the framework DOES propagate the routed profile
identity — v0.23.x passes `agent_identity` (derived from
`get_active_profile_name()`, which honors the gateway's per-session home
override) into the provider's `initialize()` — so the namespace can simply
be derived, with no per-profile configuration anywhere.

What the patch does (v2, convention over configuration)
-------------------------------------------------------
It prepends two rungs on top of the plugin's existing resolution order
(MEMINI_NAMESPACE > handshake > local git/cwd derivation):

  1. Convention: `<base>/<agent_identity>` — the resolved base namespace
     (the generic MEMINI_NAMESPACE value, default "hermes") plus the
     session's profile identity as a child. New profiles get their own
     sub-namespace on first write with zero configuration, and every
     profile keeps the shared root as an ancestor, so durable facts stored
     at the root (and in the X-Memini-Home leg) still cascade down.
  2. Optional override: MEMINI_NAMESPACE_<PROFILE> still wins for that
     profile when set — an escape hatch, not a requirement.

Contexts without an agent_identity (bare shells, non-gateway processes)
keep the upstream resolution unchanged.

Ops notes
---------
- The hermes HelmRelease init container runs this file (fetched from this
  repo) after the upstream plugin fetch on every pod start.
- Migration from the v1 env-map patch: a plugin file carrying the v1
  marker has the v1 block stripped before the v2 block is inserted, so a
  restart after this lands upgrades the live plugin in place (a plugin pin
  bump refetches upstream and the v2 block re-applies the same way).
- Idempotent via the v2 marker comment; it refuses to touch the file
  (warning on stderr only) when the upstream anchor moved — a pin bump
  refetches the upstream file and then re-applies this same reviewed patch
  automatically.
- Nothing here is a secret: namespace names are not credentials, and the
  only server-side secret involved (MEMINI_API_KEY) already ships via the
  memini-api-keys ExternalSecret.

Run:  python3 memini-per-profile-namespace.py [path-to-plugin-__init__.py]
"""
from __future__ import annotations

import sys

DEFAULT_PATH = "/opt/data/plugins/memini/__init__.py"

V1_MARKER = "# in-repo patch: per-profile namespace pin"
V2_MARKER = "# in-repo patch: per-profile namespace convention (v2)"
# v1 block runs from its marker line through this final assignment; used to
# strip the previous patch out of an already-patched plugin file.
V1_END = 'self._namespace_source = "env:per-profile"'

ANCHOR = """        ns, source = _resolve_namespace(self._cwd, hs)
        self._namespace = ns or "hermes"
        self._namespace_source = source if ns else "local-default"
"""

PATCH = ANCHOR + f"""
        {V2_MARKER} — see the docstring of
        # kubernetes/apps/llm/hermes/app/memini-per-profile-namespace.py in
        # k8s-home-ops: the framework passes the routed profile identity as
        # kwargs["agent_identity"], so the namespace is derived from it and
        # no per-profile env map is needed. The X-Memini-Home leg is
        # unaffected. MEMINI_NAMESPACE_<PROFILE> stays as an optional
        # per-profile override.
        _pp_agent = str(kwargs.get("agent_identity") or "").strip()
        if _pp_agent:
            _pp_child = _pp_agent.lower()
            if "/" in _pp_child:
                self._namespace = _pp_child
                self._namespace_source = "convention:agent-identity"
            else:
                self._namespace = (ns or "hermes") + "/" + _pp_child
                self._namespace_source = "convention:agent-identity"
            _pp_key = "MEMINI_NAMESPACE_" + _pp_agent.upper().replace("-", "_").replace("/", "_")
            _pp_pin = _env(_pp_key)
            if _pp_pin:
                self._namespace = _pp_pin
                self._namespace_source = "env:per-profile"
"""


def _strip_v1(src: str) -> str:
    """Remove a v1 patch block (marker line through its final assignment)."""
    start = src.find(V1_MARKER)
    if start == -1:
        return src
    end = src.find(V1_END, start)
    if end == -1:
        # Marker without the expected tail: leave the file alone rather
        # than guess at the block's extent.
        return src
    end += len(V1_END)
    if end < len(src) and src[end] == "\n":
        end += 1
    return src[:start] + src[end:]


def main() -> int:
    path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_PATH
    try:
        with open(path, encoding="utf-8") as fh:
            src = fh.read()
    except OSError as exc:
        print(f"WARN: per-profile namespace patch: cannot read {path}: {exc}")
        return 0
    if V2_MARKER in src:
        return 0
    src = _strip_v1(src)
    if ANCHOR not in src:
        print(
            "WARN: per-profile namespace patch: upstream anchor not found "
            "(the pinned plugin file changed); leaving the plugin unpatched"
        )
        return 0
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(src.replace(ANCHOR, PATCH, 1))
    print(f"per-profile namespace patch (v2, convention) applied to {path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
