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
#   ./build.sh --check                → run pre-flight checks only
#   ./build.sh -o draft.pdf           → override the output path
# ─────────────────────────────────────────────────────────────

set -euo pipefail

# ── Arguments ────────────────────────────────────────────────
CONFIG="project.yaml"
OUTPUT_OVERRIDE=""
CHECK_ONLY=0

print_help() {
  cat <<'HELP'
Simple Doc Lite — Build Script

Usage:  ./build.sh [options] [config-file]

Arguments:
  config-file   Path to a YAML config file (default: project.yaml).
                Overrides values from master.yaml — only include
                fields you want to change.

Options:
  -o, --output PATH   Write the PDF to PATH instead of the config's output:
  --check             Run the pre-flight checks and exit without building
  -h, --help          Show this help

Examples:
  ./build.sh                         Use project.yaml (default)
  ./build.sh client-acme.yaml        Use a named config
  ./build.sh configs/draft-v2.yaml   Use a config in a subdirectory
  ./build.sh -o drafts/v2.pdf        Build to a different output path
  ./build.sh --check                 Verify the setup without building

The output path and input file list are read from the config file
(output: and input-files: fields). See project.yaml for reference.
HELP
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) print_help; exit 0 ;;
    --check)   CHECK_ONLY=1 ;;
    -o|--output)
      if [[ $# -lt 2 ]]; then
        echo "ERROR: $1 requires a path argument."; exit 1
      fi
      OUTPUT_OVERRIDE="$2"; shift ;;
    -*)
      echo "ERROR: Unknown option: $1 (see --help)"; exit 1 ;;
    *) CONFIG="$1" ;;
  esac
  shift
done

# ── Read values from config ──────────────────────────────────
# Quoted values keep everything between the quotes (so "#" and spaces
# are safe); unquoted values end at a space-preceded "#" comment.

_parse_scalar() {  # _parse_scalar <key> <file>
  awk -v key="$1" '
    index($0, key ":") == 1 {
      sub(/^[^:]*:[[:space:]]*/, "")
      if ($0 ~ /^"/)          { sub(/^"/, "");       sub(/".*$/, "") }
      else if ($0 ~ /^'"'"'/) { sub(/^'"'"'/, "");   sub(/'"'"'.*$/, "") }
      else                    { sub(/[[:space:]]+#.*$/, ""); sub(/[[:space:]]*$/, "") }
      if (length($0) > 0) { print; exit }
    }' "$2" 2>/dev/null || true
}

# Effective value: the config wins, master.yaml supplies the default.
_effective() {
  local v
  v=$(_parse_scalar "$1" "$CONFIG")
  [[ -n "$v" ]] || v=$(_parse_scalar "$1" master.yaml)
  printf '%s\n' "$v"
}

_parse_inputs() {
  awk '
    /^input-files:/ { in_list=1; next }
    in_list {
      # blank lines and comment lines may appear between items
      if ($0 ~ /^[[:space:]]*(#|$)/) next
      # a list item ("- file"), indented or at column 0
      if ($0 ~ /^[[:space:]]*-([[:space:]]|$)/) {
        line = $0
        sub(/^[[:space:]]*-[[:space:]]*/, "", line)
        if (line ~ /^"/)          { sub(/^"/, "", line);     sub(/".*$/, "", line) }
        else if (line ~ /^'"'"'/) { sub(/^'"'"'/, "", line); sub(/'"'"'.*$/, "", line) }
        else                      { sub(/[[:space:]]+#.*$/, "", line); sub(/[[:space:]]*$/, "", line) }
        if (length(line) > 0) print line
        next
      }
      # anything else (the next key) ends the list
      exit
    }
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
  pandoc_major="${pandoc_version%%.*}"
  echo "  Found pandoc $pandoc_version"
  if [[ -n "$pandoc_major" && "$pandoc_major" -lt 3 ]]; then
    echo "ERROR: Simple Doc requires pandoc 3.0 or later (found $pandoc_version)."
    echo "       Update from https://pandoc.org/installing.html"
    errors=1
  fi
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

  OUTPUT=$(_parse_scalar output "$CONFIG")
  OUTPUT="${OUTPUT:-../output.pdf}"
  [[ -n "$OUTPUT_OVERRIDE" ]] && OUTPUT="$OUTPUT_OVERRIDE"

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

# Non-fatal notes: placeholder metadata and missing fonts.
if [[ $errors -eq 0 ]]; then
  doc_title=$(_effective title)
  doc_date=$(_effective date)
  if [[ -z "$doc_title" || "$doc_title" == "Title" ]]; then
    echo "  NOTE: title: is still the placeholder — set it in $CONFIG."
  fi
  if [[ "$doc_date" == "YYYY-MM-DD" || "$doc_date" == "Date" ]]; then
    echo "  NOTE: date: is still the placeholder — set it in $CONFIG."
  fi

  # Font availability (informational — the template falls back to Latin
  # Modern on its own if a font can't be loaded).
  if command -v fc-list &>/dev/null; then
    # One family name per line, so "Noto Sans" doesn't false-match
    # "Noto Sans Kannada".
    installed_fonts=$(fc-list : family 2>/dev/null | tr ',' '\n' | sort -u || true)
    check_font() {
      local label="$1" font="$2"
      [[ -z "$font" ]] && return 0
      if ! grep -qixF "$font" <<<"$installed_fonts"; then
        echo "  NOTE: $label font \"$font\" isn't listed by fc-list."
        echo "        If it isn't installed, the PDF falls back to Latin Modern."
      fi
    }
    check_font "Body"    "$(_effective font-body)"
    check_font "Heading" "$(_effective font-heading)"
    check_font "Mono"    "$(_effective font-mono)"
  fi
fi

if [[ $errors -ne 0 ]]; then
  echo ""
  echo "Build aborted — fix the errors above and try again."
  exit 1
fi

if [[ $CHECK_ONLY -eq 1 ]]; then
  echo ""
  echo "Pre-flight OK — ready to build (config: $CONFIG, output: $OUTPUT)."
  exit 0
fi

echo ""
echo "Building PDF → $OUTPUT"

# The output directory must exist before pandoc writes into it.
outdir=$(dirname "$OUTPUT")
mkdir -p "$outdir"

# Stop kpathsea from trying to *generate* missing fonts (mktextfm etc.).
# When a configured font isn't installed, the template detects it and falls
# back gracefully — but without this, XeLaTeX's probe of the missing name
# prints pages of harmless-but-scary METAFONT errors first.
export MKTEXTFM=0 MKTEXPK=0 MKTEXMF=0

# master.yaml supplies defaults; CONFIG overrides only what you've set.
# --resource-path lets images be found relative to the config file and
# the project root as well as the current directory.
LOG="$outdir/build.log"
build_status=0
pandoc --from markdown+raw_tex+autolink_bare_uris \
       --metadata-file master.yaml \
       --metadata-file "$CONFIG" \
       --template template.tex \
       --pdf-engine=xelatex \
       --lua-filter gfm-to-latex.lua \
       --resource-path=".:$(dirname "$CONFIG"):.." \
       "${INPUT_FILES[@]}" \
       -o "$OUTPUT" >"$LOG" 2>&1 || build_status=$?

if [[ $build_status -ne 0 ]]; then
  echo ""
  echo "BUILD FAILED — full output saved to $LOG. Last lines:"
  echo "─────────────────────────────────────────────────────"
  tail -n 15 "$LOG"
  echo "─────────────────────────────────────────────────────"
  if grep -q "fontspec Error" "$LOG"; then
    echo "HINT: A font could not be loaded. Check the font names in your"
    echo "      config, or install the fonts listed in the README."
  fi
  if grep -Eq "\.sty['\"]? not found|\.sty not found" "$LOG"; then
    echo "HINT: A LaTeX package is missing. On Ubuntu/Debian, install:"
    echo "      sudo apt install texlive-latex-extra texlive-fonts-recommended"
  fi
  if grep -q "Could not fetch\|not found in resource path\|does not exist\|Unable to load picture" "$LOG"; then
    echo "HINT: A referenced file (often an image) could not be found."
    echo "      Image paths are resolved relative to this directory."
  fi
  exit $build_status
fi

rm -f "$LOG"
echo "Done → $OUTPUT"
