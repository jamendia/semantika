--[==[
  filter-gloss.lua -- interlinear glosses (Leipzig glossing rules)

  Authoring syntax: a fenced div with class `gloss` containing ONE pipe table.

      ::: {.gloss}
      | 오늘은    | 날씨가      | 아주 | 좋습니다        |
      |-----------|-------------|------|-----------------|
      | 오늘-은   | 날씨-가     | 아주 | 좋-습니다       |
      | today-TOP | weather-NOM | very | good-POLITE.PRS |
      | 'The weather is very good today.' |
      :::

  Row 1 is the object-language line, the following rows are the morpheme
  glosses, and a final row holding a single cell becomes the free
  translation, spanning every column.  A word that contains several
  morphemes gets one column per morpheme (leave the neighbouring cells empty)
  so that the morphemes line up vertically, as the Leipzig rules require.
]==]

local function cell_blocks(cell)
  return cell.contents or {}
end

local function is_empty(cell)
  local blocks = cell_blocks(cell)
  if #blocks == 0 then return true end
  return pandoc.utils.stringify(blocks) == ""
end

local function all_rows(tbl)
  local rows = {}
  if tbl.head then
    for _, r in ipairs(tbl.head.rows) do table.insert(rows, r) end
  end
  for _, body in ipairs(tbl.bodies or {}) do
    for _, r in ipairs(body.body or {}) do table.insert(rows, r) end
  end
  if tbl.foot then
    for _, r in ipairs(tbl.foot.rows) do table.insert(rows, r) end
  end
  return rows
end

-- pandoc renamed colspan/rowspan to col_span/row_span; support both
local function set_spans(c, colspan, rowspan)
  local ok = pcall(function()
    c.col_span = colspan
    c.row_span = rowspan
  end)
  if not ok then
    c.colspan = colspan
    c.rowspan = rowspan
  end
end

local function get_colspan(c)
  return c.col_span or c.colspan or 1
end

-- ---------------------------------------------------------------- row model
-- -> { rows = { { cells = { {blocks=..., span=...}, ... } }, ... }, ncols }
local function model(tbl)
  local ncols = #tbl.colspecs
  local src = all_rows(tbl)
  local rows = {}

  for i, row in ipairs(src) do
    local nonempty, only = 0, nil
    for j, c in ipairs(row.cells) do
      if not is_empty(c) then
        nonempty = nonempty + 1
        only = j
      end
    end

    local cells = {}
    if i == #src and ncols > 1 and nonempty == 1 then
      table.insert(cells, {
        blocks = cell_blocks(row.cells[only]),
        span = ncols,
        free = true,
      })
    else
      for _, c in ipairs(row.cells) do
        table.insert(cells, { blocks = cell_blocks(c), span = get_colspan(c) })
      end
    end
    table.insert(rows, cells)
  end

  return { rows = rows, ncols = ncols }
end

-- ---------------------------------------------------------------- html
local function html_table(m)
  local rows = {}
  for _, cells in ipairs(m.rows) do
    local out = {}
    for _, c in ipairs(cells) do
      local cell = pandoc.Cell(c.blocks)
      cell.alignment = pandoc.AlignLeft
      set_spans(cell, c.span, 1)
      if c.free then cell.attr = pandoc.Attr("", { "ling-gloss-free" }) end
      table.insert(out, cell)
    end
    table.insert(rows, pandoc.Row(out))
  end

  local colspecs = {}
  for _ = 1, m.ncols do
    table.insert(colspecs, { pandoc.AlignLeft })
  end

  return pandoc.Table(
    pandoc.Caption({}),
    colspecs,
    pandoc.TableHead({}, pandoc.Attr()),
    { pandoc.TableBody(rows, {}, 0, pandoc.Attr()) },
    pandoc.TableFoot({}, pandoc.Attr()),
    pandoc.Attr("", { "ling-gloss-table" })
  )
end

-- ---------------------------------------------------------------- latex
local function latex_inline(blocks)
  local s = pandoc.write(pandoc.Pandoc(blocks), "latex")
  s = s:gsub("^%s+", ""):gsub("%s+$", "")
  s = s:gsub("\n%s*\n", "\n")
  s = s:gsub("%s*\n%s*", " ")
  return s
end

local function latex_table(m)
  local spec = "@{}" .. string.rep("l@{\\hspace{0.7em}}", m.ncols - 1) .. "l@{}"
  local lines = { "\\begin{tabular}{" .. spec .. "}" }

  for _, cells in ipairs(m.rows) do
    if #cells == 1 and cells[1].span == m.ncols then
      table.insert(lines, string.format(
        "\\multicolumn{%d}{@{}l@{}}{%s} \\\\",
        m.ncols, latex_inline(cells[1].blocks)))
    else
      local parts = {}
      for i = 1, m.ncols do
        local c = cells[i]
        table.insert(parts, c and latex_inline(c.blocks) or "")
      end
      table.insert(lines, table.concat(parts, " & ") .. " \\\\")
    end
  end

  table.insert(lines, "\\end{tabular}")
  return pandoc.RawBlock("latex", table.concat(lines, "\n"))
end

-- ---------------------------------------------------------------- main
function Div(el)
  if not el.classes:includes("gloss") then return nil end

  local tbl = nil
  for _, b in ipairs(el.content) do
    if b.t == "Table" then
      tbl = b
      break
    end
  end
  if not tbl then return nil end

  local m = model(tbl)

  if quarto.doc.isFormat("latex") or quarto.doc.isFormat("pdf") then
    el.classes = pandoc.List({ "ling-gloss" })
    el.content = { latex_table(m) }
    return el
  end

  el.classes = pandoc.List({ "ling-gloss" })
  el.content = { html_table(m) }
  return el
end
