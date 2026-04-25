# Simple Doc Lite v1.1.2

A free, open-source Markdown-to-PDF template. Write in plain Markdown, configure in a single YAML file, run a build script, get a polished PDF. No LaTeX knowledge required.

**Built on:** [Pandoc](https://pandoc.org) + XeLaTeX

---

## Quick Start

### 1. Install prerequisites

- **Pandoc 3.0+** — [pandoc.org/installing](https://pandoc.org/installing.html)
- **A TeX distribution** with XeLaTeX — TeX Live (Linux/macOS) or MiKTeX (Windows)
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
├── master.yaml
├── content/
│   └── 01-introduction.md
└── images/
    └── logo.png
```

### 3. Configure `master.yaml`

```yaml
title: "My Document"
author: "Your Name"
date: "2025-06-15"
```

### 4. Build

```bash
chmod +x build.sh
./build.sh
```

Your PDF appears as `output.pdf`.

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

**Images** — auto-centered, width-constrained:

```markdown
![Caption](images/photo.png){ width=60% }
```

**Tables** — standard pipe tables with automatic column widths.

**Code blocks** — fenced with optional language tag for syntax highlighting.

**Page breaks** — every `#` H1 starts a new page automatically. Exception: in short-form mode, H1s do *not* force page breaks (so a multi-section memo flows continuously). Use `\newpage` for a manual break.

---

## Core configuration

| Field                     | Default       | Description                        |
|---------------------------|---------------|------------------------------------|
| `title`, `author`, `date` | —             | Document metadata                  |
| `version`                 | *(empty)*     | Version string on title page       |
| `short-form`              | `false`       | Compact page-1 header vs full title page |
| `short-form-image-height` | `2.2in`       | Max banner height in short-form    |
| `logo`                    | *(empty)*     | Path to logo image                 |
| `disclaimer`              | *(empty)*     | Disclaimer box (long-form only)    |
| `toc`                     | `true`        | Show table of contents             |
| `toc-depth`               | `2`           | TOC heading levels (1–6)           |
| `secnumdepth`             | `2`           | Section numbering depth            |
| `papersize`               | `letter`      | `letter` or `a4`                   |
| `fontsize`                | `11pt`        | Base font size                     |
| `font-body`               | `Noto Sans`   | Body text font                     |
| `font-heading`            | `Noto Sans`   | Heading font                       |
| `font-mono`               | `Noto Sans Mono` | Monospace font                  |
| `color-heading`           | `25,55,120`   | Heading color, R,G,B               |
| `color-link`              | `40,80,180`   | Link color, R,G,B                  |

Callout colors (`color-note`, `color-tip`, etc.) accept LaTeX color names: `red`, `blue`, `green`, `orange`, `yellow`, `violet`, `black`, `gray`.

---

## Troubleshooting

**"Font not found"** — Install Noto Sans (see Quick Start). Check what's installed with `fc-list | grep -i noto`.

**"xelatex not found"** — Install a TeX distribution.

**"pandoc: Unknown reader: gfm-alerts"** — Your Pandoc is too old. Update to 3.0+.

**Callouts rendering as plain blockquotes** — Make sure `build.sh` uses `--from gfm-alerts`.

**Permission denied on build.sh** — `chmod +x build.sh`

---

## Upgrade to Simple Doc Pro

This Lite version covers everything you need for most documents. If you want the following features, check out **[Simple Doc Pro](YOUR_GUMROAD_URL)**:

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
