--[[
  filter-deriv.lua -- semantic derivations

  ::: {.deriv}
  ⟦the cat⟧ = ιx[cat(x)]
  ⟦chased the mouse⟧ = λy.λx[chase(x, y, ιz[mouse(z)])]
  ⟦the cat chased the mouse⟧ = chase(ιx[cat(x)], ιz[mouse(z)]) ; FA
  :::

  * Each paragraph / list item is one derivation step.
  * The first top-level `=` splits the step into a right-aligned left
    side and a left-aligned right side, so the `=` signs line up.
  * An optional `;` splits off a right-hand note column (rule name,
    justification, ...).  Inline formatting is preserved everywhere.
  * An ordered list turns into a numbered "step" column.
]]

local function is_eq(x)
  return x.t == "Str" and x.text:sub(1, 1) == "=" and #x.text <= 3
end

local function is_semi(x)
  return x.t == "Str" and x.text:sub(-1) == ";" and #x.text <= 3
end

local function split_at(inlines, pred, start)
  local lhs, rest = {}, {}
  local found = nil
  for i, x in ipairs(inlines) do
    if not found and i >= (start or 1) and pred(x) then
      found = x
    elseif found then
      table.insert(rest, x)
    else
      table.insert(lhs, x)
    end
  end
  return lhs, found, rest
end

local function trim(inlines)
  -- drop leading/trailing spaces
  local out = {}
  for _, x in ipairs(inlines) do table.insert(out, x) end
  while #out > 0 and (out[1].t == "Space" or out[1].t == "SoftBreak") do
    table.remove(out, 1)
  end
  while #out > 0 and (out[#out].t == "Space" or out[#out].t == "SoftBreak") do
    table.remove(out)
  end
  return out
end

local function parse_step(inlines, step_label)
  local body = trim(inlines)
  local note = nil

  -- split off a trailing note ("... ; RULE")
  local before_note, semi, after = split_at(body, is_semi)
  if semi and #trim(after) > 0 then
    body = trim(before_note)
    note = trim(after)
  end

  local lhs, op, rhs = split_at(body, is_eq)
  if not op then
    -- no equation: whole line is a right-side annotation
    return { label = step_label, lhs = {}, op = {}, rhs = body, note = note }
  end
  return {
    label = step_label,
    lhs = trim(lhs),
    op = { op },
    rhs = trim(rhs),
    note = note,
  }
end

-- Markdown joins consecutive source lines into one paragraph, so a step
-- per line has to be recovered from the SoftBreaks.
local function split_lines(inlines)
  local lines, cur = {}, pandoc.Inlines({})
  for _, x in ipairs(inlines) do
    if x.t == "SoftBreak" or x.t == "LineBreak" then
      table.insert(lines, cur)
      cur = pandoc.Inlines({})
    else
      cur:insert(x)
    end
  end
  if #cur > 0 then table.insert(lines, cur) end
  if #lines == 0 then table.insert(lines, pandoc.Inlines({})) end
  return lines
end

local function collect_steps(blocks, out, counter)
  counter = counter or { n = 0 }
  for _, b in ipairs(blocks) do
    if b.t == "Para" or b.t == "Plain" then
      for _, line in ipairs(split_lines(b.content)) do
        table.insert(out, parse_step(line))
      end
    elseif b.t == "OrderedList" then
      for _, item in ipairs(b.content) do
        counter.n = counter.n + 1
        local label = pandoc.Inlines({
          pandoc.Str("(" .. tostring(counter.n) .. ")")
        })
        local first = true
        for _, ib in ipairs(item) do
          if (ib.t == "Para" or ib.t == "Plain") and first then
            first = false
            local lines = split_lines(ib.content)
            for i, line in ipairs(lines) do
              table.insert(out, parse_step(line, i == 1 and label or nil))
            end
          else
            collect_steps({ ib }, out, counter)
          end
        end
      end
    elseif b.t == "BulletList" then
      for _, item in ipairs(b.content) do
        collect_steps(item, out, counter)
      end
    else
      collect_steps({ b }, out, counter)
    end
  end
  return out
end

-- HTML is laid out as a grid, not a table: a table cell that is asked to
-- take 100% of the width makes the browser shrink every other column to its
-- minimum, which wrapped the formulas mid-phrase.  A grid sizes each column
-- once, for all rows, and the justification column can still absorb whatever
-- width is left over.
local function html_table(data)
  local note = data.cols[#data.cols].cls == "ling-deriv-note"
  local rows = {}
  for _, step in ipairs(data.steps) do
    local cells = {}
    for i, col in ipairs(data.cols) do
      table.insert(cells, pandoc.Span(step[i] or {},
        pandoc.Attr("", { col.cls })))
    end
    table.insert(rows, pandoc.Div(cells, pandoc.Attr("", { "ling-deriv-row" })))
  end

  -- one track per column actually present: formula columns take their content
  -- width, the right-hand side may shrink, the justification column absorbs
  -- whatever is left so that it is right-aligned against the right margin
  local tracks = {}
  for _, col in ipairs(data.cols) do
    if col.cls == "ling-deriv-note" then
      -- an unnumbered derivation is centred at its natural width, so its
      -- justifications sit at the right edge of the block, not of the page;
      -- a numbered one keeps spanning the measure with the notes flush right
      table.insert(tracks, data.centered and "max-content" or "1fr")
    elseif col.cls == "ling-deriv-rhs" then
      table.insert(tracks, "auto")
    else
      table.insert(tracks, "max-content")
    end
  end

  local cls = { "ling-deriv-rows" }
  if note then table.insert(cls, "ling-deriv-has-notes") end
  return pandoc.Div(rows, pandoc.Attr("", cls,
    { style = "grid-template-columns: " .. table.concat(tracks, " ") }))
end

local function latex_inline(inlines)
  local s = pandoc.write(pandoc.Pandoc({ pandoc.Plain(inlines) }), "latex")
  s = s:gsub("^%s+", ""):gsub("%s+$", "")
  s = s:gsub("%s*\n%s*", " ")
  return s
end

local ensured_tabularx = false

-- the justification column is set flush with the right margin; tabularx is
-- the only way to let the last column absorb the remaining line width
local function ensure_tabularx()
  if ensured_tabularx then return end
  ensured_tabularx = true
  pcall(function()
    quarto.doc.include_text("in-header", "\\usepackage{tabularx}")
  end)
end

local function latex_table(data)
  local note = data.cols[#data.cols].cls == "ling-deriv-note"
  if note then ensure_tabularx() end

  local spec = {}
  for i, col in ipairs(data.cols) do
    if note and i == #data.cols then
      spec[i] = ">{\\raggedleft\\arraybackslash}X"
    else
      spec[i] = col.align == pandoc.AlignRight and "r"
        or (col.align == pandoc.AlignCenter and "c" or "l")
    end
  end
  local sep = "@{\\hspace{0.45em}}"
  local body = "@{}" .. table.concat(spec, sep) .. "@{}"
  local lines = {
    note and ("\\begin{tabularx}{\\linewidth}{" .. body .. "}")
      or ("\\begin{tabular}{" .. body .. "}")
  }
  for _, step in ipairs(data.steps) do
    local parts = {}
    for i = 1, #data.cols do
      table.insert(parts, latex_inline(step[i] or {}))
    end
    table.insert(lines, table.concat(parts, " & ") .. " \\\\")
  end
  table.insert(lines, string.format("\\end{%s}", note and "tabularx" or "tabular"))
  return pandoc.RawBlock("latex", table.concat(lines, "\n"))
end

function Div(el)
  if not el.classes:includes("deriv") then return nil end

  local steps = collect_steps(el.content, {})
  if #steps == 0 then return nil end

  local has_label, has_note = false, false
  for _, s in ipairs(steps) do
    if s.label then has_label = true end
    if s.note then has_note = true end
  end

  local cols = {}
  if has_label then
    table.insert(cols, { align = pandoc.AlignRight, cls = "ling-deriv-step" })
  end
  table.insert(cols, { align = pandoc.AlignRight, cls = "ling-deriv-lhs" })
  table.insert(cols, { align = pandoc.AlignCenter, cls = "ling-deriv-eq" })
  table.insert(cols, { align = pandoc.AlignLeft, cls = "ling-deriv-rhs" })
  if has_note then
    table.insert(cols, { align = pandoc.AlignRight, cls = "ling-deriv-note" })
  end

  local data = { cols = cols, steps = {}, centered = not has_label }
  for _, s in ipairs(steps) do
    local row = {}
    if has_label then table.insert(row, s.label or {}) end
    table.insert(row, s.lhs)
    table.insert(row, s.op)
    table.insert(row, s.rhs)
    if has_note then table.insert(row, s.note or {}) end
    table.insert(data.steps, row)
  end

  el.classes = pandoc.List(has_note and { "ling-deriv", "ling-deriv-notes" }
    or { "ling-deriv" })
  -- only the unnumbered form is centred; the numbered form (a step column)
  -- keeps its own layout untouched
  if not has_label then el.classes:insert("ling-deriv-centered") end
  if quarto.doc.isFormat("latex") or quarto.doc.isFormat("pdf") then
    el.content = { latex_table(data) }
  else
    el.content = { html_table(data) }
  end
  return el
end
