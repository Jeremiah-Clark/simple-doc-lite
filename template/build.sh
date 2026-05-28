#!/bin/bash
# ─────────────────────────────────────────────────────────────
# Simple Doc Lite v1.1.2 — Build Script
# Converts Markdown files into a styled PDF via Pandoc + XeLaTeX.
#
# All project settings live in project.yaml (or a named config).
# This script requires no edits — just point it at a config file.
#
# Usage:
#   ./build.sh                        → uses project.yaml
#   ./build.sh client-acme.yaml       → uses a named config
#   ./build.sh configs/draft-v2.yaml  → supports subdirectory configs
# ─────────────────────────────────────────────────────────────

set -euo pipefail

# ── Config file ──────────────────────────────────────────────
CONFIG="${1:-project.yaml}"

# ── Help ─────────────────────────────────────────────────────
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'HELP'
Simple Doc Lite — Build Script

Usage:  ./build.sh [config-file] [--help]

Arguments:
  config-file   Path to a YAML config file (default: project.yaml).
                Overrides values from master.yaml — only include
                fields you want to change.

Examples:
  ./build.sh                         Use project.yaml (default)
  ./build.sh client-acme.yaml        Use a named config
  ./build.sh configs/draft-v2.yaml   Use a config in a subdirectory

The output path and input file list are read from the config file
(output: and input-files: fields). See project.yaml for reference.
HELP
  exit 0
fi

# ── Read output path and input files from config ─────────────
_parse_output() {
  awk '/^output:/{
    sub(/^output:[[:space:]]*/, "")
    sub(/#.*$/, "")
    sub(/^[[:space:]]*/, ""); sub(/[[:space:]]*$/, "")
    gsub(/^["'"'"']|["'"'"']$/, "")
    if (length($0) > 0) print
  }' "$1"
}

_parse_inputs() {
  awk '
    /^input-files:/ { f=1; next }
    f && /^[[:space:]]+-/ {
      line=$0
      sub(/^[[:space:]]+-[[:space:]]*/, "", line)
      sub(/#.*$/, "", line)
      sub(/[[:space:]]*$/, "", line)
      sub(/^"/, "", line); sub(/"$/, "", line)
      sub(/^'"'"'/, "", line); sub(/'"'"'$/, "", line)
      if (length(line) > 0) print line
    }
    f && /^[^[:space:]]/ { exit }
  ' "$1"
}

# ── Pre-flight checks ────────────────────────────────────────

errors=0

if ! command -v pandoc &>/dev/null; then
  echo "ERROR: pandoc is not installed."
  echo "       Install it from https://pandoc.org/installing.html"
  errors=1
else
  pandoc_version=$(pandoc --version | head -1 | sed 's/[^0-9.]//g' | cut -d. -f1,2)
  echo "  Found pandoc $pandoc_version"
fi

if ! command -v xelatex &>/dev/null; then
  echo "ERROR: xelatex is not installed."
  echo "       Install TeX Live: sudo apt install texlive-xetex (Ubuntu)"
  echo "       or: brew install --cask mactex (macOS)"
  errors=1
else
  echo "  Found xelatex"
fi

for f in master.yaml template.tex gfm-to-latex.lua; do
  if [[ ! -f "$f" ]]; then
    echo "ERROR: Required template file not found: $f"
    errors=1
  fi
done

if [[ ! -f "$CONFIG" ]]; then
  echo "ERROR: Config file not found: $CONFIG"
  if [[ "$CONFIG" == "project.yaml" ]]; then
    echo "       Create a project.yaml in this directory, or pass a config"
    echo "       file as an argument:  ./build.sh my-config.yaml"
  else
    echo "       Check the path and filename."
  fi
  errors=1
else
  echo "  Using config: $CONFIG"

  OUTPUT=$(_parse_output "$CONFIG")
  OUTPUT="${OUTPUT:-../output.pdf}"

  INPUT_FILES=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && INPUT_FILES+=("$line")
  done < <(_parse_inputs "$CONFIG")
fi

if [[ $errors -eq 0 ]]; then
  if [[ ${#INPUT_FILES[@]} -eq 0 ]]; then
    echo "ERROR: No input files listed in $CONFIG."
    echo "       Add an input-files: list to your config."
    errors=1
  else
    for f in "${INPUT_FILES[@]}"; do
      if [[ ! -f "$f" ]]; then
        echo "ERROR: Input file not found: $f"
        echo "       Check the path in the input-files: list in $CONFIG."
        errors=1
      fi
    done
  fi
fi

if [[ $errors -ne 0 ]]; then
  echo ""
  echo "Build aborted — fix the errors above and try again."
  exit 1
fi

echo ""
echo "Building PDF → $OUTPUT"

# master.yaml supplies defaults; CONFIG overrides only what you've set.
pandoc --from gfm-alerts \
       --metadata-file master.yaml \
       --metadata-file "$CONFIG" \
       --template template.tex \
       --pdf-engine=xelatex \
       --lua-filter gfm-to-latex.lua \
       "${INPUT_FILES[@]}" \
       -o "$OUTPUT"

echo "Done → $OUTPUT"
