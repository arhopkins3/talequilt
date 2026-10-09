#!/usr/bin/env bash
# Documentation and status checks (CI job "Docs and status check").
# 1. docs/factory-status.js must load and describe every phase, stage and guardrail with a known status.
# 2. Every relative Markdown link in the repository must point at a file that exists.
# 3. Every workflow file must be valid YAML.
set -euo pipefail
cd "$(dirname "$0")/.."

node - <<'JS'
global.window = {};
require(require("path").resolve("docs/factory-status.js"));
const F = window.FACTORY;
const ok = new Set(["done", "active", "manual", "planned"]);
const bad = [];
const check = (where, s) => { if (!ok.has(s.status)) bad.push(`${where}: status "${s.status}"`); if (s.status === "planned" && s.phase == null && !where.startsWith("phase")) bad.push(`${where}: planned without a phase`); };
F.phases.forEach(p => check(`phase ${p.n}`, p));
F.stages.forEach(s => { check(s.num, s); check(`${s.num} agent`, s.agent); s.checks.forEach(c => check(`${s.num} / ${c.t}`, c)); if (s.next && s.next.gate) check(`${s.num} / ${s.next.gate}`, s.next); });
F.guardrails.forEach(g => check(`guardrail ${g.t}`, g));
if (F.phases.length !== 9 || F.stages.length !== 7) bad.push(`expected 9 phases and 7 stages, found ${F.phases.length} and ${F.stages.length}`);
if (bad.length) { console.error("factory-status.js problems:\n  " + bad.join("\n  ")); process.exit(1); }
console.log(`factory-status.js ok: ${F.phases.length} phases, ${F.stages.length} stages, ${F.guardrails.length} guardrails`);
JS

python3 - <<'PY'
import re, os, glob, sys
bad = []
for f in glob.glob("**/*.md", recursive=True):
    if "/node_modules/" in f or f.startswith("node_modules/"): continue
    text = open(f, encoding="utf-8").read()
    for m in re.finditer(r"\]\(([^)\s#:]+)(?:#[^)]*)?\)", text):
        target = m.group(1)
        if target.startswith(("http", "mailto")): continue
        p = os.path.normpath(os.path.join(os.path.dirname(f), target))
        if not os.path.exists(p): bad.append(f"{f}: {target}")
if bad:
    print("broken links:\n  " + "\n  ".join(bad)); sys.exit(1)
print("markdown links ok")
PY

python3 - <<'PY'
import glob, sys, yaml
for f in glob.glob(".github/workflows/*.yml") + glob.glob(".github/ISSUE_TEMPLATE/*.yml"):
    yaml.safe_load(open(f))
print("workflow and template yaml ok")
PY
