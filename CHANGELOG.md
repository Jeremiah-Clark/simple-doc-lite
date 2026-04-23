# Changelog

All notable changes to Simple Doc are documented in this file.

## [1.1.0] — 2026-04-22

### Added

- **Short-form layout** — new `short-form: true` toggle in `master.yaml` that replaces the full title page with a compact header block at the top of page 1. Body content flows directly beneath. Designed for memos, letters, briefs, and other short documents (1–5 pages).
- `short-form-image-height` setting to control the short-form banner's maximum height (default `2.2in`).
- Recommended image size guidance in `master.yaml` comments for both long-form (square/portrait, ≈1500 × 1500 px) and short-form (landscape banner, ≈2000 × 600 px) layouts.
- `firstpage` fancyhdr page style used on page 1 in short-form to suppress the running header while keeping the footer with page numbers.
- New "Document layouts" section in the README explaining when to use each layout.

### Changed

- `titlepage.tex` now branches on `\ifdefined\docshortform` and contains both layouts. No action needed for existing long-form documents — they render identically to 1.0.1.
- The Lua filter's H1 handler now skips the automatic page break for the *first* H1 only when `short-form: true`, so it can appear on page 1 beneath the header block. All subsequent H1s still break the page.
- TOC no longer forces a page break after itself in short-form (it would push body content to page 3 otherwise).

### Fixed

- (None — all changes are additive.)

### Migration notes

- Existing `master.yaml` files without `short-form` set default to `false`, preserving 1.0.1 behavior. No changes required.
- If you want to use short-form, add `short-form: true` and consider also setting `toc: false`.

## [1.0.1] — 2025-04-14

### Added

- Ability to scale watermark text
- Updated example to showcase more features

### Fixed

- Layering of the optional watermark (in front of everything else)
- Text highlighting conflicts resolved, new stand-alone system

## [1.0.0] — 2025-04-13

### Added
- Complete template system: `template.tex`, `titlepage.tex`, `gfm-to-latex.lua`
- YAML-driven configuration via `master.yaml`
- GFM admonition support: NOTE, TIP, WARNING, IMPORTANT, CAUTION, SUMMARY, EXAMPLE
- Custom callout titles
- Automatic image centering with width and height constraints
- Proportional table column widths
- Page breaks before H1 headings (automatic)
- Optional page breaks before H2 headings (`h2-page-break` setting)
- Colon-paragraph keepwith logic (prevents orphaned introductory lines)
- Configurable title page with logo, disclaimer, and spacing controls
- Page headers and footers with rule thickness controls
- Build a script with pre-flight checks and error handling
- Working example project with sample output
- Full configuration reference in README
- Troubleshooting guide
