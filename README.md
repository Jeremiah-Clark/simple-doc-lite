# Simple Doc Lite v1.2.0

A free, open-source Markdown-to-PDF template. 
Write in plain Markdown, configure in a single YAML file, run a build script, get a polished PDF. 
No LaTeX knowledge required.

**Built on:** [Pandoc](https://pandoc.org) + XeLaTeX

---

## Quick Start

### 1. Install prerequisites

- **Pandoc 3.0+** — [pandoc.org/installing](https://pandoc.org/installing.html)
- **A TeX distribution** with XeLaTeX — TeX Live (Linux/macOS) or MiKTeX (Windows)
  - Ubuntu/Debian: `sudo apt install texlive-xetex texlive-latex-recommended texlive-latex-extra texlive-pictures texlive-plain-generic texlive-fonts-recommended lmodern`
  - macOS: `brew install --cask mactex`
- **Noto Sans fonts**:
  - Ubuntu/Debian: `sudo apt install fonts-noto-core fonts-noto-mono`
  - macOS: `brew install --cask font-noto-sans font-noto-sans-mono`
  - Windows: [fonts.google.com/noto](https://fonts.google.com/noto)

### 2. Set up your project

```
my-project/
├── template.tex
├── titlepage.tex
├── gfm-to-latex.lua
├── build.sh
├── master.yaml        ← template defaults (no need to edit this)
├── project.yaml       ← your project config (edit this)
├── content/
│   └── 01-introduction.md
└── images/
    └── logo.png
```

### 3. Configure `project.yaml`

```yaml
output: "../output.pdf"

input-files:
  - content/01-introduction.md
  - content/02-main-body.md

title:  "My Document"
author: "Your Name"
date:   "2025-06-15"
```

`project.yaml` only needs the fields you want to set or change. 
`master.yaml` supplies defaults for everything else — you don't need to touch it.

### 4. Build

```bash
chmod +x build.sh
./build.sh
```

Your PDF appears at the path you set in `output:`. 
To use a different config file:

```bash
./build.sh configs/client-acme.yaml
```

Other build options:

```bash
./build.sh --check            # verify your setup without building
./build.sh -o drafts/v2.pdf   # build to a different output path
```

If a build fails, the full compiler output is saved to `build.log` next
to the output PDF, and the script prints the relevant last lines plus a
hint about the most common causes.

---

## Document layouts

Two layouts controlled by one YAML setting:

- **Long-form** (`short-form: false`, default) — Full title page on its own, TOC on a second page, then the body. Best for reports, manuals, and anything over five pages.
- **Short-form** (`short-form: true`) — Compact header block at the top of page 1, body flows beneath, disclaimer suppressed. Best for memos, letters, and briefs (1–5 pages). Set `toc: false` for best results.

### Recommended image sizes

| Layout      | Target size        | Aspect ratio | Notes                             |
|-------------|--------------------|--------------|-----------------------------------|
| Long-form   | 1500 × 1500 px     | Square/portrait | Centered on title page          |
| Short-form  | 2000 × 600 px      | ~3:1 to 4:1  | Landscape banner, full text width |

---

## Writing content

Standard Markdown, plus:

**GFM-style callouts**

```markdown
> [!NOTE]
> Supplementary information.

> [!WARNING] Custom title
> Add custom text on the marker line.
```

Available types: `NOTE`, `TIP`, `WARNING`, `IMPORTANT`, `CAUTION`, `SUMMARY`, `EXAMPLE`.

**Images** — auto-centered, width-constrained; the alt text renders as a
small caption under the image (set `figure-captions: false` to disable):

```markdown
![Caption](images/photo.png){ width=60% }
```

Pixel widths (`{ width=300px }`) and percentages both work. 
Images that appear inline with text keep their natural size.

**Task lists** — `- [x]` / `- [ ]` items render with GitHub-style
checkboxes in place of bullets.

**Tables** — standard pipe tables. Small tables keep their natural
size; wide tables get proportional column widths so they never overflow.

**Code blocks** — fenced with optional language tag for syntax
highlighting. Long lines wrap inside the shaded box.

**Page breaks** — every `#` H1 starts a new page automatically. Exception: in short-form mode, H1s do *not* force page breaks (so a multi-section memo flows continuously). Use `\newpage` for a manual break.

**Numbering without H1s** — if a document's top-level heading is `##` (no `#` anywhere — common when the title page already carries the title), H2s are numbered as top-level sections (`1`, `2`, ...) automatically instead of `0.1`, `0.2`.

**Multi-file documents** — list files in order under `input-files:` in your `project.yaml`:

```yaml
input-files:
  - content/01-introduction.md
  - content/02-methodology.md
  - content/03-conclusion.md
```

---

## Core configuration

All settings go in `project.yaml`. Every field is optional except `output` and `input-files`.

| Field                     | Default          | Description                              |
| ------------------------- | ---------------- | ---------------------------------------- |
| `output`                  | `../output.pdf`  | Output PDF path                          |
| `input-files`             | *(required)*     | Ordered list of Markdown files           |
| `title`, `author`, `date` | —                | Document metadata                        |
| `version`                 | *(empty)*        | Version string on title page             |
| `short-form`              | `false`          | Compact page-1 header vs full title page |
| `short-form-image-height` | `2.2in`          | Max banner height in short-form          |
| `logo`                    | *(empty)*        | Path to logo image                       |
| `disclaimer`              | *(empty)*        | Disclaimer box (long-form only)          |
| `toc`                     | `true`           | Show table of contents                   |
| `toc-depth`               | `2`              | TOC heading levels (1–6)                 |
| `secnumdepth`             | `2`              | Section numbering depth                  |
| `figure-captions`         | `true`           | Show image alt text as captions          |
| `papersize`               | `letter`         | `letter` or `a4`                         |
| `fontsize`                | `11pt`           | Base font size                           |
| `font-body`               | `Noto Sans`      | Body text font                           |
| `font-heading`            | `Noto Sans`      | Heading font                             |
| `font-mono`               | `Noto Sans Mono` | Monospace font                           |
| `color-heading`           | `25,55,120`      | Heading color, R,G,B                     |
| `color-link`              | `40,80,180`      | Link color, R,G,B                        |

Callout colors (`color-note`, `color-tip`, etc.) default to a tuned palette (`sd-red`, `sd-blue`, `sd-orange`, `sd-green`, `sd-amber`, `sd-purple`, `sd-gray`) chosen for readable white title text. 
Plain LaTeX color names (`red`, `blue`, `green`, ...) also work.

**Fonts and languages** — if a configured font isn't installed, the build doesn't fail: it falls back to Latin Modern (bundled with every TeX distribution) and prints a console note. 
For non-Latin scripts (Cyrillic, Greek, CJK, ...), set `font-body` to a font that covers your script — characters a font doesn't cover can't appear in the PDF. `lang:` (e.g., `en-US`, `de-DE`) controls hyphenation.

---

## Troubleshooting

**"Config file not found: project.yaml"** — Create a `project.yaml` in your project directory (use the included one as a starting point), or pass a config file explicitly: `./build.sh my-config.yaml`

**"No input files listed"** — Make sure your `project.yaml` has an `input-files:` list with at least one file.

**"Font not found" console note** — the build still succeeds using Latin Modern; install Noto Sans (see Quick Start) to get the intended look. 
Check what's installed with `fc-list | grep -i noto`, or run `./build.sh --check`.

**"xelatex not found"** — Install a TeX distribution.

**Pandoc version errors** — Simple Doc requires Pandoc 3.0 or later. 
Update from [pandoc.org/installing](https://pandoc.org/installing.html).

**Callouts rendering as plain blockquotes** — Make sure `build.sh` uses `--from markdown+raw_tex+autolink_bare_uris`. 
Using `--from gfm` causes Pandoc to natively parse alerts before the Lua filter can handle them.

**Permission denied on build.sh** — `chmod +x build.sh`

---

## Upgrade to Simple Doc Pro

This Lite version covers everything you need for most documents. 
If you want the following features, check out **[Simple Doc Pro](YOUR_GUMROAD_URL)**:

- **Watermarks** — "DRAFT", "CONFIDENTIAL", or any text, angled across every page
- **Page X of Y** — total page count in the footer
- **Custom headers** — left/center/right header content on every page
- **Auto-date** — use today's date automatically on every build
- **H2 page breaks** — start each subsection on a fresh page
- **Font fallback system** — NF (Nerd Font) primary with automatic standard-Noto fallback when NF isn't installed
- **Working example project** with a prebuilt sample PDF
- **Complete user guide** with in-depth configuration reference and customization tips

---

## License

MIT — see [LICENSE](LICENSE). Use it however you like.
