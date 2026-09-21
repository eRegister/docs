#!/usr/bin/env bash
# =============================================================================
# scripts/sync-v1-toolkit.sh — copy the v1 upgrade toolkit guide into this site.
#
# The guide is written and reviewed in the upgrade-to-v1 repo, beside the code
# it documents, so that a change to a script and the change to its documentation
# land in the same commit. This script copies that source of truth into
# docs/ereg/v1/ and adapts it to Material for MkDocs:
#
#   * GitHub alert callouts (`> [!WARNING]`) become `!!! warning` admonitions,
#     which is what the rest of this site uses. The flavour comes from the
#     marker, not from guessing at the wording
#   * the YAML front matter the PDF build needs is replaced with a plain
#     `title:` that MkDocs reads for the nav
#
# Nothing else is rewritten: the markdown is deliberately portable.
#
#   ./scripts/sync-v1-toolkit.sh [path-to-upgrade-to-v1-checkout]
#
# Default source: ../upgrade-to-v1 beside this repo. Override with
# EREGISTER_TOOLKIT_DIR.
#
# After running it, check `mkdocs build --strict` before committing.
# =============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_REPO="${1:-${EREGISTER_TOOLKIT_DIR:-$(cd "$HERE/.." && pwd)/upgrade-to-v1}}"
SRC="${SRC_REPO}/docs/guide"
DEST="${HERE}/docs/ereg/v1"

[ -d "$SRC" ] || {
  echo "No guide at ${SRC}" >&2
  echo "Pass the upgrade-to-v1 checkout as \$1, or set EREGISTER_TOOLKIT_DIR." >&2
  exit 1
}

mkdir -p "$DEST"

# Remove pages that no longer exist upstream, so a renamed chapter does not
# leave an orphan behind. Only ever touches this one directory.
for f in "$DEST"/*.md; do
  [ -e "$f" ] || continue
  [ -e "${SRC}/$(basename "$f")" ] || { echo "removing stale $(basename "$f")"; rm -f "$f"; }
done

count=0
for f in "$SRC"/*.md; do
  b="$(basename "$f")"
  python3 - "$f" "${DEST}/${b}" <<'PY'
import re, sys

src, dst = sys.argv[1], sys.argv[2]
text = open(src, encoding="utf-8").read()

# 1. YAML front matter: the PDF build uses title+subtitle; MkDocs wants a title.
m = re.match(r"\A---\n(.*?)\n---\n", text, re.S)
if m:
    title = re.search(r'^title:\s*"?(.*?)"?\s*$', m.group(1), re.M)
    head = f'---\ntitle: {title.group(1)}\n---\n' if title else ""
    text = head + text[m.end():]

# 2. GitHub alerts -> Material admonitions. The flavour is taken from the
#    marker the source carries, never guessed from the prose: a heuristic over
#    wording silently mislabels a "data loss" callout as a note the first time
#    someone rephrases it.
FLAVOUR = {
    "NOTE": "note",
    "TIP": "tip",
    "IMPORTANT": "info",
    "WARNING": "warning",
    "CAUTION": "danger",
}

def convert(match):
    raw = match.group(0)
    lines = [re.sub(r"^> ?", "", ln) for ln in raw.rstrip("\n").split("\n")]
    kind = "note"
    m = re.match(r"\[!([A-Z]+)\]\s*$", lines[0])
    if m:
        kind = FLAVOUR.get(m.group(1), "note")
        lines = lines[1:]
    body = "\n".join(lines).strip()
    if not body or body.startswith("```"):
        return raw
    indented = "\n".join(("    " + ln).rstrip() for ln in body.split("\n"))
    return f"!!! {kind}\n\n{indented}\n"

# Only whole blockquote blocks that are not inside a fenced code block.
parts = re.split(r"(?ms)(^```.*?^```\n)", text)
for i in range(0, len(parts), 2):
    parts[i] = re.sub(r"(?ms)^> .*?(?=\n(?!>)|\Z)\n?", convert, parts[i])
text = "".join(parts)

open(dst, "w", encoding="utf-8").write(text)
PY
  count=$((count + 1))
done

echo "synced ${count} page(s) from ${SRC} -> ${DEST}"
echo "now run:  mkdocs build --strict"
