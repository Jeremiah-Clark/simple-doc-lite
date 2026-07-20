# SimpleDoc Lite v1.2.0

SimpleDoc Lite is a free, open-source Markdown-to-PDF template. 
It allows you to write in plain Markdown, configure everything in one YAML file, run a build script, and get a polished PDF. 
No LaTeX knowledge is required.

**Built on:** [Pandoc](https://pandoc.org) + XeLaTeX

---

## Quick Start

### 1. Install Prerequisites

- **Pandoc 3.0+**
  - Download the installer for your OS: [pandoc.org/installing](https://pandoc.org/installing.html)
  - macOS: You can also use [Homebrew](https://brew.sh/): `brew install pandoc`
  - Ubuntu/Debian: The pandoc package in Ubuntu/Debian's repositories may be older than 3.0—use the installer from pandoc.org instead.
- **A TeX distribution** with XeLaTeX — TeX Live (Linux/macOS) or MiKTeX (Windows)
  - macOS: `brew install --cask mactex` or [the MacTex installer](https://tug.org/mactex/mactex-download.html)
  - Ubuntu/Debian: `sudo apt install texlive-xetex texlive-latex-recommended texlive-latex-extra texlive-pictures texlive-plain-generic texlive-fonts-recommended lmodern`
  - Windows: [MiKTeX](https://miktex.org/download)
    - `build.sh` is a bash script — run it from [Git Bash](https://gitforwindows.org/) or WSL.
- **Noto Sans fonts**:
  - macOS: `brew install --cask font-noto-sans font-noto-sans-mono`
  - Ubuntu/Debian: `sudo apt install fonts-noto-core fonts-noto-mono`
  - Any OS: [fonts.google.com/noto](https://fonts.google.com/noto)

### 2. Set Up Your Project

```markdown
my-project/
├── content/                 ← Put your .md files in this folder
│   └── 01-introduction.md
├── images/                  ← Put your image files in this folder
│   └── logo.png
└── template/                ← The SimpleDoc template files folder
    ├── build.sh                 ← (do not edit) PDF build script
    ├── configs/                 ← (optional) for saving multiple config files
    ├── gfm-to-latex.lua         ← (do not edit) LaTeX conversion script
    ├── master.yaml              ← (do not edit) template defaults
    ├── project.yaml             ← Your project config file
    ├── template.tex             ← (do not edit) general page template
    └── titlepage.tex            ← (do not edit) title page template
```

### 3. Configure `project.yaml`

All of your document setup is done in the `project.yaml` file. 
At the very least, update the identifying information and input/output details at the top of the file:

```yaml
output: "../output.pdf"

input-files:
  - ../content/01-introduction.md
  - ../content/02-main-body.md

title:  "My Document"
author: "Your Name"
date:   "2025-06-15"
```

`project.yaml` only needs the fields you want to set or change. 
Any settings not set in `project.yaml` will default to the settings in the `master.yaml` file.

### 4. Build

In the terminal, navigate to the `template` folder.
The first time you build, you will need to make the `build.sh` file executable:

```bash
chmod +x build.sh
```

To create the PDF, run `build.sh`:

```bash
./build.sh
```

Your PDF appears at the path you set in `output:`. 
You can save multiple config files (a subfolder such as `configs/` keeps things organized) and call them as needed.
If no config file is specified, the `project.yaml` file in the `template` directory will be used.

To use a saved config file:

```bash
./build.sh configs/client-acme.yaml
```

Other build options:

```bash
./build.sh --check            # verify your setup without building
./build.sh -o drafts/v2.pdf   # build to a different output path
```

If a build fails, the full compiler output is saved to `build.log` next to the output PDF, and the script prints the relevant last lines plus a hint about the most common causes.

---

## Document Layouts

There are two layout options controlled by one YAML setting:

- **Long-form** (`short-form: false`, default) — The Long-form layout has a full title page and a full Table of Contents (TOC) page, followed by the body text. Best for reports, manuals, and anything over five pages.
- **Short-form** (`short-form: true`) — Short-form has a header block at the top of page 1, and the body text begins beneath that. The optional title page disclaimer is suppressed (if you still need it, add it to the top of the body text). Best for memos, letters, and briefs (1–5 pages).

### Recommended Logo Image Sizes

| Layout      | Target size        | Aspect ratio | Notes                             |
|-------------|--------------------|--------------|-----------------------------------|
| Long-form   | 1500 × 1500 px     | Square/portrait | Centered on title page          |
| Short-form  | 2000 × 600 px      | ~3:1 to 4:1  | Landscape banner; width adjustable with `short-form-image-width` |

---

## Writing Content

Write your document using standard [Markdown syntax](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax/), plus:

**GFM-style callouts**—These render as colored boxes with a title bar. 
Each callout type has its own color; override them with the `color-*` keys in `project.yaml`.

```markdown
> [!NOTE]
> Supplementary information.

> [!WARNING] Custom title
> Add custom text on the marker line.
```
Example:  
<img width="480" height="96" alt="gfm-callout1" src="https://github.com/user-attachments/assets/a3e01715-3e7b-4616-aaaf-b27fafd636e7" />

Available types: `NOTE`, `TIP`, `WARNING`, `IMPORTANT`, `CAUTION`, `SUMMARY`, `EXAMPLE`.

**Images**—Images are auto-centered and width-constrained. 
The image alt text renders as a small caption under the image (set `figure-captions: false` to disable):

```markdown
![Caption](images/photo.png){ width=60% }
```

Pixel widths (`{ width=300px }`) and percentages both work. 
If no width is set, the image will default to 80% of text width. 
Images that appear inline with text keep their natural size.

**Task lists**—`- [x]` / `- [ ]` items render with GitHub-style checkboxes in place of bullets.

**Tables**—Standard pipe tables. 
Small tables keep their natural size; wide tables get proportional column widths so they never overflow.

**Code blocks**—Fenced with optional language tag for syntax highlighting. 
Long lines wrap inside the shaded box.

**Page breaks**—Every `#` H1 starts a new page in Long-form mode. 
In Short-form mode, H1s do *not* force page breaks (so a multi-section memo flows continuously). 
Use `\newpage` for a manual break.

**Numbering without H1s**—If a document's top-level heading is `##` (no `#` anywhere in your content—common when the title page already carries the title), H2s are numbered as top-level sections (`1`, `2`, ...) automatically instead of `0.1`, `0.2` (to turn off section numbering entirely, set `secnumdepth: 0`).

**Multi-file documents**—Files will be assembled in the order set under `input-files:` in your `project.yaml`:

```yaml
input-files:
  - ../content/01-introduction.md
  - ../content/02-methodology.md
  - ../content/03-conclusion.md
```

---

## Core Configuration

All settings go in `project.yaml`. 
Every field is optional except `output` and `input-files`.

| Field                     | Default          | Description                              |
| ------------------------- | ---------------- | ---------------------------------------- |
| `output`                  | `../output.pdf`  | Output PDF path                          |
| `input-files`             | *(required)*     | Ordered list of Markdown files           |
| `title`, `author`, `date` | —                | Document metadata                        |
| `version`                 | *(empty)*        | Version string on title page             |
| `short-form`              | `false`          | Compact page-1 header vs full title page |
| `short-form-image-height` | `2.2in`          | Max banner height in short-form          |
| `short-form-image-width`  | `1.0`            | Banner width, fraction of text width     |
| `logo`                    | *(empty)*        | Path to logo image                       |
| `disclaimer`              | *(empty)*        | Disclaimer box (long-form only)          |
| `toc`                     | `true`           | Show table of contents                   |
| `toc-depth`               | `2`              | TOC heading levels (1–6)                 |
| `secnumdepth`             | `2`              | Section numbering depth                  |
| `figure-captions`         | `true`           | Show image alt text as captions          |
| `callout-keep-whole`      | `false`          | Never split a callout across pages       |
| `papersize`               | `letter`         | `letter` or `a4`                         |
| `fontsize`                | `11pt`           | Base font size                           |
| `font-body`               | `Noto Sans`      | Body text font                           |
| `font-heading`            | `Noto Sans`      | Heading font                             |
| `font-mono`               | `Noto Sans Mono` | Monospace font                           |
| `color-heading`           | `25,55,120`      | Heading color, R,G,B                     |
| `color-link`              | `40,80,180`      | Link color, R,G,B                        |

The full key list—margins, header/footer rules, line spacing, title-page spacing, lang, subject/keywords—is in project.yaml, with comments. 

Callout colors (`color-note`, `color-tip`, etc.) default to a tuned palette (`sd-red`, `sd-blue`, `sd-orange`, `sd-green`, `sd-amber`, `sd-purple`, `sd-gray`) chosen for readable white title text. 
Plain LaTeX color names (`red`, `blue`, `green`, ...) are also supported.

**Fonts and languages**—If a configured font isn't installed, the build falls back to Latin Modern (bundled with every TeX distribution) and prints a console note. 
For non-Latin scripts (Cyrillic, Greek, CJK, ...), set `font-body` to a font that covers your script—characters a font doesn't cover can't appear in the PDF. 
`lang:` (e.g., `en-US`, `de-DE`) controls hyphenation.

---

## Troubleshooting

**"Config file not found: project.yaml"**—Create a `project.yaml` in the template directory (use the included one as a starting point), or pass a config file explicitly: `./build.sh configs/my-config.yaml`

**"No input files listed"**—Make sure your `project.yaml` has an `input-files:` list with at least one file.

**"Font not found" console note**—The build still succeeds using Latin Modern; install Noto Sans (see Quick Start) to get the intended look. 
Check what's installed with `fc-list | grep -i noto`, or run `./build.sh --check`.

**"xelatex not found"**—Install a TeX distribution.

**Pandoc version errors**—SimpleDoc Lite requires Pandoc 3.0 or later. 
Update from [pandoc.org/installing](https://pandoc.org/installing.html).

**Callouts rendering as plain blockquotes**—Make sure `build.sh` uses `--from markdown+raw_tex+autolink_bare_uris`. 
Using `--from gfm` causes Pandoc to natively parse alerts before the Lua filter can handle them.

**Permission denied on build.sh**—Run `chmod +x build.sh` from within the `template/` folder in the project directory.

---

## Upgrade to SimpleDoc Pro

This Lite version covers everything you need for most documents. 
If you want the following features, check out **[SimpleDoc Pro](YOUR_GUMROAD_URL)**:

- **Watermarks**—"DRAFT", "CONFIDENTIAL", or any text, angled across every page
- **Page X of Y**—total page count in the footer
- **Custom headers**—left/center/right header content on every page
- **Auto-date**—use today's date automatically on every build
- **H2 page breaks**—start each subsection on a fresh page
- **Font fallback system**—NF (Nerd Font) primary with automatic standard-Noto fallback when NF isn't installed
- **Working example project** with a prebuilt sample PDF
- **Complete user guide** with in-depth configuration reference and customization tips

---

## License

MIT — see [LICENSE](LICENSE). Use it however you like, though I’d appreciate a link back.
