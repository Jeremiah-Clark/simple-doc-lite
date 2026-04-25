#!/bin/bash
# ─────────────────────────────────────────────────────────────
# Simple Doc Lite v1.1.1 — Build Script
# Converts Markdown files into a styled PDF via Pandoc + XeLaTeX.
# ─────────────────────────────────────────────────────────────

set -euo pipefail

# ── Configuration ────────────────────────────────────────────

# EDIT BELOW TO MATCH YOUR PROJECT:

OUTPUT="output.pdf"

# List your Markdown content files below, in reading order.
INPUT_FILES=(
  content/01-introduction.md
  content/02-main-body.md
  # Add more files here, one per line
)

# DO NOT EDIT BELOW THIS LINE  ──────────────────────────────────

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'EOF'
Simple Doc Lite — Build Script

Usage:  ./build.sh [--help]

Before running:
  1. Install Pandoc 3.0+     → https://pandoc.org/installing.html
  2. Install a TeX distro    → TeX Live (Linux/macOS) or MiKTeX (Windows)
  3. Install Noto Sans fonts (see README)
  4. Edit the INPUT_FILES list at the top of this script
  5. Edit master.yaml with your document metadata

Then run:  ./build.sh
EOF
  exit 0
fi

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

if [[ ${#INPUT_FILES[@]} -eq 0 ]]; then
  echo "ERROR: No input files listed."
  echo "       Edit the INPUT_FILES array at the top of build.sh."
  errors=1
else
  for f in "${INPUT_FILES[@]}"; do
    if [[ ! -f "$f" ]]; then
      echo "ERROR: Input file not found: $f"
      errors=1
    fi
  done
fi

if [[ $errors -ne 0 ]]; then
  echo ""
  echo "Build aborted — fix the errors above and try again."
  exit 1
fi

echo ""
echo "Building PDF..."

pandoc --from gfm-alerts \
       --metadata-file master.yaml \
       --template template.tex \
       --pdf-engine=xelatex \
       --lua-filter gfm-to-latex.lua \
       "${INPUT_FILES[@]}" \
       -o "$OUTPUT"

echo "Done → $OUTPUT"
