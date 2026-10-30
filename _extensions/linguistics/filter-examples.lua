--[[
  filter-examples.lua -- numbered linguistic examples

      ::: {.ex}
      The cat sat on the mat.
      :::

  * Top-level examples are numbered (1), (2), (3), ... in document order.
  * An `.ex` nested inside another `.ex` is a sub-example and is labelled
    a., b., c. ... -- no parentheses, no number of its own.  The first
    sub-example sits on the same line as the parent number:

        (5)  a.  Juan compró el libro.
             b.  *Compró el libro.
             c.  Él lo compró.

    Cross-references to a sub-example still resolve to the conventional
    (5a) form.
  * Optional attributes:
        #ex-cat           anchor, referencable with [ex-cat]{.exref}
        judgment="*"      judgment marker printed before the example
        preamble="Mary:"  context / speaker line before the example
        letter="c"        force a sub-example letter
        num="A1"          force the number of a top-level example
]]

local numbers = {}     -- identifier -> "1" / "5a" style label
local counter = 0

local function letter_for(n)
  local s = ""
  while n > 0 do
    local r = (n - 1) % 26
    s = string.char(97 + r) .. s
    n = math.floor((n - 1) / 26)
  end
  return s
end

-- ------------------------------------------------------------------ pass 1
local function number_blocks(blocks, parent, depth)
  for _, b in ipairs(blocks) do
    if b.t == "Div" and b.classes:includes("ex") then
      local num, letter
      if parent then
        parent.count = parent.count + 1
        letter = b.attributes["letter"] or letter_for(parent.count)
        num = parent.num .. letter
      else
        counter = counter + 1
        num = b.attributes["num"] or tostring(counter)
      end
      b.attributes["ling-num"] = num
      b.attributes["ling-depth"] = tostring(depth)
      if letter then b.attributes["ling-letter"] = letter end

      if b.identifier ~= "" then
        numbers[b.identifier] = num
      end
      number_blocks(b.content, { num = num, count = 0 }, depth + 1)
    elseif b.t == "Div" then
      number_blocks(b.content, parent, depth)
    elseif b.t == "OrderedList" or b.t == "BulletList" then
      for _, item in ipairs(b.content) do
        number_blocks(item, parent, depth)
      end
    elseif b.t == "BlockQuote" then
      number_blocks(b.content, parent, depth)
    end
  end
end

-- ------------------------------------------------------------------ helpers
local function utf8len(s)
  local n = 0
  for _ in utf8.codes(s) do n = n + 1 end
  return n
end

-- Judgment markers are set in a box of a fixed width so that the example
-- text of every sibling starts at the same column, judged or not.  The box
-- is one character wide per character of the widest marker in the group,
-- plus a single space before the text (the CSS padding / \hspace below).
local JUDGE_CHAR_EM = 0.5

local function latex_escape(s)
  s = s:gsub("\\", "\\textbackslash{}")
  s = s:gsub("([#$%%&_{}])", "\\%1")
  s = s:gsub("%^", "\\textasciicircum{}")
  s = s:gsub("~", "\\textasciitilde{}")
  return s
end

local function prefix_inlines(el, judgw)
  local out = {}
  local pre = el.attributes["preamble"]
  if pre and pre ~= "" then
    table.insert(out, pandoc.Span(
      pandoc.Inlines(pandoc.read(pre, "markdown").blocks[1].content),
      pandoc.Attr("", { "ling-preamble" })
    ))
    table.insert(out, pandoc.Space())
  end
  local jm = el.attributes["judgment"] or ""
  local width = math.max(judgw or 0, utf8len(jm))
  if width > 0 then
    local em = string.format("%.2fem", width * JUDGE_CHAR_EM)
    if quarto.doc.isFormat("latex") or quarto.doc.isFormat("pdf") then
      -- \  is exactly one interword space, matching the CSS padding
      table.insert(out, pandoc.RawInline("latex", string.format(
        "\\makebox[%s][l]{%s}\\ ", em, latex_escape(jm))))
    elseif quarto.doc.isFormat("html") or quarto.doc.isFormat("revealjs") then
      table.insert(out, pandoc.Span(pandoc.Str(jm),
        pandoc.Attr("", { "ling-judgment" }, { style = "min-width:" .. em })))
    else
      table.insert(out, pandoc.Str(jm .. string.rep(" ", width - utf8len(jm) + 1)))
    end
  end
  return out
end

-- widest judgment marker among a list of examples
local function judgment_width(children)
  local w = 0
  for _, c in ipairs(children) do
    w = math.max(w, utf8len(c.attributes["judgment"] or ""))
  end
  return w
end

local function with_prefix(blocks, el, judgw)
  local pre = prefix_inlines(el, judgw)
  if #pre == 0 then return blocks end
  local out = pandoc.Blocks({})
  local placed = false
  for _, b in ipairs(blocks) do
    if not placed and b.t == "Para" then
      local inl = pandoc.Inlines(pre)
      for _, x in ipairs(b.content) do table.insert(inl, x) end
      out:insert(pandoc.Para(inl))
      placed = true
    else
      out:insert(b)
    end
  end
  if not placed then out:insert(1, pandoc.Para(pre)) end
  return out
end

-- own content vs. nested sub-examples
local function split_content(el)
  local own, children = {}, {}
  for _, b in ipairs(el.content) do
    if b.t == "Div" and b.classes:includes("ex") then
      table.insert(children, b)
    else
      table.insert(own, b)
    end
  end
  return own, children
end

local function sub_letter(el)
  return el.attributes["ling-letter"] or "a"
end

-- ------------------------------------------------------------------ html
-- body of an example: its own blocks plus, if any, the stack of
-- sub-examples a., b., c. sharing one letter column
local function html_body(el, judgw)
  local own, children = split_content(el)
  local out = pandoc.Blocks({})
  for _, b in ipairs(with_prefix(own, el, judgw)) do out:insert(b) end

  if #children > 0 then
    local jw = judgment_width(children)
    local rows = {}
    for _, c in ipairs(children) do
      table.insert(rows, pandoc.Div({
        pandoc.Span(pandoc.Str(sub_letter(c) .. "."),
          pandoc.Attr("", { "ling-sub-label" })),
        pandoc.Div(html_body(c, jw), pandoc.Attr(c.identifier, { "ling-sub-body" })),
      }, pandoc.Attr("", { "ling-subex" })))
    end
    out:insert(pandoc.Div(rows, pandoc.Attr("", { "ling-sublist" })))
  end

  return out
end

local function render_html(el)
  local num = el.attributes["ling-num"]
  return pandoc.Div({
    pandoc.Span(pandoc.Str("(" .. num .. ")"),
      pandoc.Attr("", { "ling-ex-num" })),
    pandoc.Div(html_body(el), pandoc.Attr("", { "ling-ex-body" })),
  }, pandoc.Attr(el.identifier, { "ling-ex" }))
end

-- ------------------------------------------------------------------ latex
local function latex_body(el, judgw)
  local own, children = split_content(el)
  local inner = pandoc.write(pandoc.Pandoc(with_prefix(own, el, judgw)), "latex")
  inner = inner:gsub("%s+$", "")

  if #children > 0 then
    local jw = judgment_width(children)
    local parts = {}
    for _, c in ipairs(children) do
      table.insert(parts, string.format(
        "\\noindent\\begin{minipage}[t]{1.7em}\\vspace{0pt}%s.\\end{minipage}%%\n" ..
        "\\begin{minipage}[t]{\\dimexpr\\linewidth-1.7em\\relax}\\vspace{0pt}%%\n" ..
        "%s\\end{minipage}",
        sub_letter(c), latex_body(c, jw)))
    end
    local stack = table.concat(parts, "\n\\par\\vspace{0.35em}\n")
    if inner ~= "" then
      inner = inner .. "\n\\par\\vspace{0.5em}\n" .. stack
    else
      inner = stack
    end
  end

  return inner
end

local function render_latex(el)
  local num = el.attributes["ling-num"]
  local inner = latex_body(el)

  -- \vspace{0pt} makes [t] align on the real top of the box, so the number
  -- stays level with the first line even when it is a table
  local head = string.format(
    "\\noindent\\begin{minipage}[t]{2.6em}\\vspace{0pt}\\raggedright (%s)\\end{minipage}%%\n" ..
    "\\begin{minipage}[t]{\\dimexpr\\linewidth-2.6em\\relax}\\vspace{0pt}" ..
    "\\setlength{\\parindent}{0pt}%%\n", num)
  return pandoc.RawBlock("latex",
    head .. inner .. "\n\\end{minipage}\\par\\medskip")
end

-- ------------------------------------------------------------------ other
-- plain fallback for formats without a dedicated renderer
local function plain_body(el, out, indent, judgw)
  local own, children = split_content(el)
  for _, b in ipairs(with_prefix(own, el, judgw)) do out:insert(b) end
  local jw = judgment_width(children)
  for _, c in ipairs(children) do
    local blocks = pandoc.Blocks({})
    plain_body(c, blocks, indent .. "  ", jw)
    local first = blocks[1]
    local head = pandoc.Inlines({ pandoc.Str(indent .. sub_letter(c) .. ". ") })
    if first and first.t == "Para" then
      for _, x in ipairs(first.content) do table.insert(head, x) end
      blocks[1] = pandoc.Para(head)
    else
      blocks:insert(1, pandoc.Para(head))
    end
    for _, b in ipairs(blocks) do out:insert(b) end
  end
end

local function render_plain(el)
  local num = el.attributes["ling-num"]
  local out = pandoc.Blocks({})
  plain_body(el, out, "")
  local head = pandoc.Inlines({ pandoc.Str("(" .. num .. ") ") })
  local first = out[1]
  if first and first.t == "Para" then
    for _, x in ipairs(first.content) do table.insert(head, x) end
    out[1] = pandoc.Para(head)
  else
    out:insert(1, pandoc.Para(head))
  end
  return pandoc.Div(out, pandoc.Attr(el.identifier, { "ling-ex" }))
end

-- ------------------------------------------------------------------ main
function Div(el)
  local num = el.attributes["ling-num"]
  if not num then return nil end
  -- sub-examples are laid out by their parent, never on their own
  if el.attributes["ling-depth"] ~= "0" then return nil end

  if quarto.doc.isFormat("latex") or quarto.doc.isFormat("pdf") then
    return render_latex(el)
  end
  if quarto.doc.isFormat("html") or quarto.doc.isFormat("revealjs") then
    return render_html(el)
  end
  return render_plain(el)
end

-- Quarto only applies `contributes.formats` stylesheets for format
-- extensions, so the stylesheet is embedded directly for HTML output.
local css_injected = false

local function inject_css()
  if css_injected then return end
  css_injected = true
  if not (quarto.doc.isFormat("html") or quarto.doc.isFormat("revealjs")) then return end
  local src = (debug.getinfo(1, "S").source or ""):gsub("^@", "")
  local dir = src:match("^(.*)[/\\][^/\\]*$") or "."
  local f = io.open(dir .. "/linguistics.css", "r")
  if not f then return end
  local css = f:read("*a")
  f:close()
  if css and #css > 0 then
    pcall(function()
      quarto.doc.include_text("in-header", "<style>\n" .. css .. "\n</style>")
    end)
  end
end

function Pandoc(doc)
  numbers, counter = {}, 0
  inject_css()
  number_blocks(doc.blocks, nil, 0)

  doc = doc:walk({ Div = Div })

  -- resolve [ex-cat]{.exref} references
  doc = doc:walk({
    Span = function(s)
      if not s.classes:includes("exref") then return nil end
      local key = pandoc.utils.stringify(s.content)
      key = key:match("^%s*(.-)%s*$")
      local num = numbers[key]
      if not num then return nil end
      return pandoc.Span(pandoc.Str("(" .. num .. ")"),
        pandoc.Attr("", { "ling-ex-ref" }))
    end
  })
  return doc
end
