-- ─────────────────────────────────────────────────────────────
-- Simple Doc Lite v1.1.0 — Lua Filter
-- https://github.com/YOUR_GITHUB/simple-doc
-- Copyright (c) 2025 Jeremiah Clark. MIT License.
-- ─────────────────────────────────────────────────────────────
-- gfm-to-latex.lua
-- Bridges GitHub-Flavored Markdown features to LaTeX for PDF generation.
--
-- IMPORTANT: build.sh must use --from gfm-alerts (not --from gfm) so that
-- Pandoc does NOT natively parse GFM alerts. This keeps them as BlockQuotes,
-- allowing this filter to convert them into our custom LaTeX environments.
--
-- Handles:
--   1. GFM admonitions (> [!WARNING], > [!TIP], etc.) → LaTeX mdframed environments
--   2. Images — centered, width-constrained, and height-constrained to fit the page
--   3. Page breaks before level-1 headings (skipped for the first H1 in short-form)
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
}

function BlockQuote(el)
  if #el.content == 0 then return el end

  local first_block = el.content[1]
  if first_block.t ~= "Para" then return el end

  local first_text = pandoc.utils.stringify(first_block)
  local admonition_type = first_text:match("^%[!(%u+)%]")

  if not admonition_type then return el end

  local env_name = admonition_map[admonition_type]
  if not env_name then return el end

  local custom_title = first_text:match("^%[!%u+%]%s+(.+)$")

  local new_content = pandoc.List()
  for i = 2, #el.content do
    new_content:insert(el.content[i])
  end

  local result = pandoc.List()
  if custom_title and custom_title ~= "" then
    result:insert(pandoc.RawBlock("latex", "\\begin{" .. env_name .. "}[" .. custom_title .. "]"))
  else
    result:insert(pandoc.RawBlock("latex", "\\begin{" .. env_name .. "}"))
  end
  result:extend(new_content)
  result:insert(pandoc.RawBlock("latex", "\\end{" .. env_name .. "}"))

  return result
end

-- ---------------------------------------------------------------------------
-- 2. Images — centered, width- and height-constrained
-- ---------------------------------------------------------------------------
local function make_includegraphics(src, width_str)
  local pct = width_str:match("^(%d+)%%$")
  local latex_width = pct
    and string.format("%.2f\\linewidth", tonumber(pct) / 100)
    or width_str
  return "\\includegraphics[width=" .. latex_width
    .. ",height=0.82\\textheight,keepaspectratio]{" .. src .. "}"
end

function Figure(el)
  local img = el.content[1]
  if img and img.t == "Plain" then
    local inner = img.content[1]
    if inner and inner.t == "Image" then
      local width = inner.attributes.width or "80%"
      return {
        pandoc.RawBlock("latex", "\\begin{center}"),
        pandoc.RawBlock("latex", make_includegraphics(inner.src, width)),
        pandoc.RawBlock("latex", "\\end{center}"),
      }
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

function Image(el)
  if not el.attributes.width and not el.attributes.height then
    el.attributes.width = "80%"
  end
  return el
end

-- ---------------------------------------------------------------------------
-- 3. Page breaks before H1 headings
-- ---------------------------------------------------------------------------
-- \newpage before H1 — each major section starts on a fresh page.
--   Exception: in short-form mode, the FIRST H1 does not force a page break,
--   so it can flow directly beneath the header block on page 1.

local short_form    = false
local first_h1_seen = false

function Meta(meta)
  if meta["short-form"] then
    short_form = meta["short-form"]
  end
end

function Header(el)
  if el.level == 1 then
    if short_form and not first_h1_seen then
      first_h1_seen = true
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

function Table(el)
  local n = #el.colspecs
  if n == 0 then return el end

  local total = 0
  for _, spec in ipairs(el.colspecs) do
    total = total + (spec[2] or 0)
  end

  local widths
  if total < 0.01 then
    local lens = col_content_lengths(el)
    local sum = 0
    for _, l in ipairs(lens) do sum = sum + l end
    widths = {}
    for i, l in ipairs(lens) do widths[i] = l / sum end
  else
    widths = {}
    for i, spec in ipairs(el.colspecs) do
      widths[i] = (spec[2] or 0) / total
    end
  end

  for i = 1, n do
    el.colspecs[i] = { el.colspecs[i][1], widths[i] }
  end

  return el
end

-- ---------------------------------------------------------------------------
-- 5. Keep colon-ending paragraphs with the following block
-- ---------------------------------------------------------------------------
function Pandoc(doc)
  local new_blocks = pandoc.List()
  for i, block in ipairs(doc.blocks) do
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
