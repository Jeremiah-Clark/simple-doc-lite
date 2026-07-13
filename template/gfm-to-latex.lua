-- ─────────────────────────────────────────────────────────────
-- Simple Doc Lite v1.2.0 — Lua Filter
-- https://github.com/YOUR_GITHUB/simple-doc
-- Copyright (c) 2025 Jeremiah Clark. MIT License.
-- ─────────────────────────────────────────────────────────────
-- gfm-to-latex.lua
-- Bridges GitHub-Flavored Markdown features to LaTeX for PDF generation.
--
-- IMPORTANT: build.sh must use --from markdown+raw_tex+autolink_bare_uris.
-- The markdown reader does not natively parse GFM alerts, so callouts remain
-- as BlockQuotes for this filter to convert into styled LaTeX environments.
-- raw_tex enables inline/block LaTeX passthrough (\newpage, \begin{center},
-- etc.) in content files. autolink_bare_uris restores bare URL autolinking.
--
-- Handles:
--   1. GFM admonitions (> [!WARNING], > [!TIP], etc.) → LaTeX mdframed environments
--   2. Images — centered, width-constrained, and height-constrained to fit the page
--   3. Page breaks before level-1 headings (suppressed entirely in short-form)
--   4. Proportional table column widths
--   5. Keep colon-ending paragraphs with the following block

-- ---------------------------------------------------------------------------
-- 1. GFM Admonitions → LaTeX callout environments
-- ---------------------------------------------------------------------------
local admonition_map = {
  WARNING   = "warning",
  NOTE      = "note",
  TIP       = "tip",
  IMPORTANT = "important",
  CAUTION   = "caution",
  SUMMARY   = "summary",
  EXAMPLE   = "example",
}

-- Render title inlines through the LaTeX writer so special characters
-- (& % # _ ...) arrive escaped instead of breaking the build.
local function inlines_to_latex(inlines)
  local latex = pandoc.write(pandoc.Pandoc({ pandoc.Plain(inlines) }), "latex")
  return latex:gsub("%s*\n%s*", " "):gsub("^%s+", ""):gsub("%s+$", "")
end

function BlockQuote(el)
  if #el.content == 0 then return el end

  local first_block = el.content[1]
  if first_block.t ~= "Para" then return el end

  local inlines = first_block.content
  local first = inlines[1]
  if not first or first.t ~= "Str" then return el end

  -- The marker must be the first word of the quote: [!TYPE] (any case)
  local admonition_type = first.text:match("^%[!(%a+)%]$")
  if not admonition_type then return el end

  local env_name = admonition_map[admonition_type:upper()]
  if not env_name then return el end

  -- Split the rest of the first paragraph at the first line break.
  -- Inlines before the break form an optional custom title; inlines after
  -- it are body content — the standard GFM form
  --   > [!NOTE]
  --   > Body text.
  -- parses as ONE paragraph with a SoftBreak after the marker, so the
  -- body must not be mistaken for a title.
  local title_inlines = pandoc.List()
  local body_inlines  = pandoc.List()
  local past_break = false
  for i = 2, #inlines do
    local inline = inlines[i]
    if not past_break and (inline.t == "SoftBreak" or inline.t == "LineBreak") then
      past_break = true
    elseif past_break then
      body_inlines:insert(inline)
    elseif not (inline.t == "Space" and #title_inlines == 0) then
      title_inlines:insert(inline)
    end
  end

  local new_content = pandoc.List()
  if #body_inlines > 0 then
    new_content:insert(pandoc.Para(body_inlines))
  end
  for i = 2, #el.content do
    new_content:insert(el.content[i])
  end

  local result = pandoc.List()
  if #title_inlines > 0 then
    -- Braces keep a "]" in the title from ending the optional argument.
    result:insert(pandoc.RawBlock("latex",
      "\\begin{" .. env_name .. "}[{" .. inlines_to_latex(title_inlines) .. "}]"))
  else
    result:insert(pandoc.RawBlock("latex", "\\begin{" .. env_name .. "}"))
  end
  result:extend(new_content)
  result:insert(pandoc.RawBlock("latex", "\\end{" .. env_name .. "}"))

  return result
end

-- ---------------------------------------------------------------------------
-- 1b. Mid-length and long inline code → width-aware (chips can't wrap)
-- ---------------------------------------------------------------------------
-- Short snippets always keep the boxed inline-code style from
-- template.tex. Anything long enough to risk crowding a line goes
-- through \simpledocsmartcode, which measures the snippet against the
-- current line width at typesetting time: it stays a chip where it fits
-- comfortably and is set unboxed (breakable at spaces and after common
-- separators) where the line is narrow — callouts, lists — or the
-- snippet is simply too wide.

local SMART_CODE_THRESHOLD = 30

function Code(el)
  if #el.text <= SMART_CODE_THRESHOLD then return nil end
  if el.attr and #el.attr.classes > 0 then return nil end

  -- Render through the writer so escaping matches Pandoc's own \texttt output
  local latex = pandoc.write(pandoc.Pandoc({ pandoc.Plain({ el }) }), "latex")
  latex = latex:gsub("%s*\n%s*", " "):gsub("^%s+", ""):gsub("%s+$", "")
  local inner = latex:match("^\\texttt{(.*)}$")
  if not inner then return nil end

  -- Allow breaks after separators (never touching escape sequences,
  -- which all start with a backslash).
  inner = inner:gsub("([/%.,=:;])", "%1\\allowbreak{}")

  return pandoc.RawInline("latex", "\\simpledocsmartcode{" .. inner .. "}")
end

-- ---------------------------------------------------------------------------
-- 2. Images — centered, width- and height-constrained
-- ---------------------------------------------------------------------------
local function image_width_to_latex(width_str)
  local pct = width_str:match("^(%d+%.?%d*)%%$")
  if pct then
    return string.format("%.2f\\linewidth", tonumber(pct) / 100)
  end
  -- Pixel widths ("300px") and unitless HTML-style numbers ("300") have
  -- no LaTeX unit and would abort the build; convert at the usual 96 dpi.
  local px = width_str:match("^(%d+%.?%d*)px$") or width_str:match("^(%d+%.?%d*)$")
  if px then
    return string.format("%.3fin", tonumber(px) / 96)
  end
  return width_str
end

local function make_includegraphics(src, width_str)
  return "\\includegraphics[width=" .. image_width_to_latex(width_str)
    .. ",height=0.82\\textheight,keepaspectratio]{" .. src .. "}"
end

local figure_captions = true   -- set from Meta (figure-captions:)

function Figure(el)
  local img = el.content[1]
  if img and img.t == "Plain" then
    local inner = img.content[1]
    if inner and inner.t == "Image" then
      local width = inner.attributes.width or "80%"
      local blocks = pandoc.List({
        pandoc.RawBlock("latex", "\\begin{center}"),
        pandoc.RawBlock("latex", make_includegraphics(inner.src, width)),
      })
      -- The alt text becomes a small, muted caption under the image
      -- (disable with figure-captions: false).
      if figure_captions and el.caption and el.caption.long then
        local cap = pandoc.utils.blocks_to_inlines(el.caption.long)
        if #cap > 0 then
          blocks:insert(pandoc.RawBlock("latex",
            "{\\small\\color{black!60} " .. inlines_to_latex(cap) .. "}"))
        end
      end
      blocks:insert(pandoc.RawBlock("latex", "\\end{center}"))
      return blocks
    end
  end
end

function Para(el)
  if #el.content == 1 and el.content[1].t == "Image" then
    local img = el.content[1]
    local width = img.attributes.width or "80%"
    return {
      pandoc.RawBlock("latex", "\\begin{center}"),
      pandoc.RawBlock("latex", make_includegraphics(img.src, width)),
      pandoc.RawBlock("latex", "\\end{center}"),
    }
  end
end

-- NOTE: standalone images (their own paragraph or figure) get the 80%
-- default from the Figure/Para handlers above. Images that appear inline
-- with text, in list items, or in table cells keep their natural size
-- (capped at the line width by template.tex) — a blanket width would blow
-- small inline icons up to 80% of the page.

-- ---------------------------------------------------------------------------
-- 3. Page breaks before H1 headings
-- ---------------------------------------------------------------------------
-- \newpage before H1 — each major section starts on a fresh page.
--   Exception: in short-form mode, NO H1 forces a page break. The first H1
--   flows beneath the header block on page 1, and subsequent H1s flow
--   inline as the document continues — appropriate for short documents
--   (memos, letters, briefs) where forcing page breaks per H1 would
--   produce awkwardly fragmented output.

local short_form = false

-- YAML booleans arrive as real booleans, but users sometimes quote them
-- ("false") — treat the usual false-y spellings as false instead of
-- silently enabling the feature.
local function truthy(v)
  if v == nil or v == false then return false end
  if v == true then return true end
  local s = pandoc.utils.stringify(v):lower()
  return not (s == "false" or s == "no" or s == "off" or s == "0" or s == "")
end

function Meta(meta)
  short_form = truthy(meta["short-form"])
  if meta["figure-captions"] ~= nil then
    figure_captions = truthy(meta["figure-captions"])
  end
end

-- ---------------------------------------------------------------------------
-- 3b. Task-list checkboxes
-- ---------------------------------------------------------------------------
-- GFM task lists arrive as ☒/☐ characters; most fonts lack the glyphs and
-- the default LaTeX mapping renders a harsh "boxed times". Map them to the
-- styled checkboxes defined in template.tex.

function Str(el)
  if el.text == "☒" then return pandoc.RawInline("latex", "\\sdtaskdone{}") end
  if el.text == "☐" then return pandoc.RawInline("latex", "\\sdtaskopen{}") end
end

-- When EVERY item in a bullet list is a task item, drop the bullets and
-- let the checkboxes stand as the item labels (GitHub-style). Mixed
-- lists keep their bullets with inline checkboxes.
-- (Inline handlers run first, so the markers are already RawInlines.)
local function task_mark(inline)
  if inline and inline.t == "RawInline" and inline.format == "latex" then
    if inline.text == "\\sdtaskdone{}" then return "\\sdtaskdone{}" end
    if inline.text == "\\sdtaskopen{}" then return "\\sdtaskopen{}" end
  end
  return nil
end

function BulletList(el)
  local marks = {}
  for i, item in ipairs(el.content) do
    local first = item[1]
    if first and (first.t == "Plain" or first.t == "Para")
       and task_mark(first.content[1]) then
      marks[i] = task_mark(first.content[1])
    else
      return nil
    end
  end

  local out = pandoc.List()
  out:insert(pandoc.RawBlock("latex",
    "\\begin{itemize}[label={},leftmargin=2.4em,labelsep=0.6em]"))
  for i, item in ipairs(el.content) do
    out:insert(pandoc.RawBlock("latex", "\\item[" .. marks[i] .. "]"))
    local blocks = pandoc.List(item)
    local first_inlines = pandoc.List(blocks[1].content)
    first_inlines:remove(1)
    if first_inlines[1] and first_inlines[1].t == "Space" then
      first_inlines:remove(1)
    end
    blocks[1] = pandoc.Plain(first_inlines)
    out:extend(blocks)
  end
  out:insert(pandoc.RawBlock("latex", "\\end{itemize}"))
  return out
end

function Header(el)
  if el.level == 1 then
    if short_form then
      return el
    end
    return {
      pandoc.RawBlock("latex", "\\newpage"),
      el,
    }
  end
  return el
end

-- ---------------------------------------------------------------------------
-- 4. Tables — proportional column widths to prevent overflow
-- ---------------------------------------------------------------------------
local function col_content_lengths(el)
  local n = #el.colspecs
  local max_lens = {}
  for i = 1, n do max_lens[i] = 1 end

  local function measure(rows)
    for _, row in ipairs(rows) do
      for ci, cell in ipairs(row.cells) do
        if ci <= n then
          local len = #pandoc.utils.stringify(cell)
          if len > max_lens[ci] then max_lens[ci] = len end
        end
      end
    end
  end

  if el.head and el.head.rows then measure(el.head.rows) end
  for _, body in ipairs(el.bodies) do
    if body.body then measure(body.body) end
  end
  return max_lens
end

-- Tables that already fit are left at their natural size — stretching a
-- two-column "A | B" table across the whole page looks broken. Only
-- tables whose content would overflow the text width get proportional
-- p{} column widths. ~80 characters of single-line content roughly
-- fills the text width at the default font size.
local TABLE_CHAR_BUDGET = 80

function Table(el)
  local n = #el.colspecs
  if n == 0 then return el end

  local total = 0
  for _, spec in ipairs(el.colspecs) do
    total = total + (spec[2] or 0)
  end

  if total >= 0.01 then
    -- Author-supplied widths: respect them, but rein them in if they
    -- add up to more than the full text width.
    if total > 1.001 then
      for i = 1, n do
        el.colspecs[i] = { el.colspecs[i][1], (el.colspecs[i][2] or 0) / total }
      end
    end
    return el
  end

  local lens = col_content_lengths(el)
  local sum = 0
  for _, l in ipairs(lens) do sum = sum + l end
  if sum <= TABLE_CHAR_BUDGET then
    return el
  end

  for i = 1, n do
    el.colspecs[i] = { el.colspecs[i][1], lens[i] / sum }
  end

  return el
end

-- ---------------------------------------------------------------------------
-- 5. Whole-document passes
-- ---------------------------------------------------------------------------
-- a) Documents whose top-level heading is ## (no # anywhere — common when
--    the title page already carries the title) are renumbered so H2s
--    count as top-level sections: "1", "2" instead of "0.1", "0.2",
--    with H3s as "1.1". Only the numbers change; heading styles and
--    page flow stay the same.
-- b) Keep colon-ending paragraphs with the block that follows them.

function Pandoc(doc)
  local has_h1, has_h2 = false, false
  for _, block in ipairs(doc.blocks) do
    if block.t == "Header" then
      if block.level == 1 then has_h1 = true end
      if block.level == 2 then has_h2 = true end
    end
  end

  local new_blocks = pandoc.List()
  if not has_h1 and has_h2 then
    new_blocks:insert(pandoc.RawBlock("latex",
      "\\renewcommand{\\thesubsection}{\\arabic{subsection}}"
      .. "\\renewcommand{\\thesubsubsection}{\\thesubsection.\\arabic{subsubsection}}"))
  end

  for _, block in ipairs(doc.blocks) do
    new_blocks:insert(block)
    if block.t == "Para" then
      local inlines = block.content
      local last = inlines[#inlines]
      if last and last.t == "Str" and last.text:sub(-1) == ":" then
        new_blocks:insert(pandoc.RawBlock("latex", "\\nopagebreak[4]"))
      end
    end
  end
  doc.blocks = new_blocks
  return doc
end

-- ---------------------------------------------------------------------------
-- Filter ordering
-- ---------------------------------------------------------------------------
-- Pandoc applies filter tables in order. We need Meta to run BEFORE any
-- block-level handlers, so they can read the short-form / h2-page-break
-- flags. Without this explicit ordering, Pandoc may process Headers before
-- Meta, leaving the flags at their initial false values.

return {
  { Meta = Meta },
  {
    BlockQuote = BlockQuote,
    BulletList = BulletList,
    Code       = Code,
    Figure     = Figure,
    Para       = Para,
    Header     = Header,
    Str        = Str,
    Table      = Table,
    Pandoc     = Pandoc,
  },
}
