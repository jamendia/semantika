--[==[
  filter-tree.lua -- syntax trees

      ::: {.tree}
      [CP
        [DP_i the mouse]
        [C'
          [C will]
          [TP
            [DP t_i]
            [T'
              [T was]
              [VP
                [V chased]
                [DP the cat]]]]]]
      :::

  Bracket notation, one node per `[label ...children]`.  Inside a label:

      X'          bar levels are just text
      DP_i        a coindexation subscript (i) -- typeset only, no arrow
      t_i         a plain label; traces are ordinary nodes now
      CP^{EPP}    a superscript annotation (features, indices, ...)
      * CP        a leading judgment marker (*, **, ?, ??, %, #, !)
      DP ∅        empty / null heads are fine
      DP ...      an unexpanded node

  A leaf is a node written without brackets; `[DP the mouse]` is a leaf,
  `[DP [D the] [NP mouse]]` is a branching node.

  Lines -- movement arrows, binding, agreement, ... -- are drawn only when
  asked for.  Give any node an id with `{=id}` after its closing bracket
  (works for leaves and for branching nodes alike), then list the lines in a
  `lines` attribute of the div; one entry per `;`:

      ::: {.tree lines="t-obj -> dp-obj; cp -- tp dashed"}
      [CP
        [DP the mouse]{=dp-obj}
        [C'
          [C will]
          [TP
            [DP t]{=t-obj}
            [T' [T was] [VP [V chased] [t]]]]]]]{=cp}
      :::  `a -> b` draws a line from a to b with an arrowhead at b; `a -- b` draws a
  plain line.  Append `dashed` for a dashed line (solid otherwise).

  Where the lines go is tree-lines.lua's business: every line between nodes on
  different levels is one arc bowed to the west, scaled to the span, with both
  ends stopping just short of the labels; an arrow enters its node vertically,
  and lines meeting at one node are fanned out along its edge.  Two nodes on
  one level are joined by a straight run instead.
]==]

local FS = 15
local GAP = 0.9 * FS
local LEVEL = 2.7 * FS
local MARGIN = 0.6 * FS
local tid = 0

-- The routing engine lives in tree-lines.lua beside this filter: it takes the
-- finished layout and the lines to draw, and returns geometry, so it can be
-- read on its own without pandoc in the way.
local routing = (function()
  local here = (PANDOC_SCRIPT_FILE or ""):match("^(.*)[/\\][^/\\]*$")
  local candidates = {}
  if here then table.insert(candidates, here .. "/tree-lines.lua") end
  table.insert(candidates, "_extensions/linguistics/tree-lines.lua")
  table.insert(candidates, "tree-lines.lua")
  for _, path in ipairs(candidates) do
    local chunk = loadfile(path)
    if chunk then return chunk() end
  end
  error("linguistics: cannot find tree-lines.lua next to filter-tree.lua")
end)()

routing.configure(FS, LEVEL)

local cubic_at = routing.cubic_at
local line_geometry = routing.geometry

-- ------------------------------------------------------------------ utils
local function utf8_len(s)
  local ok, n = pcall(function()
    local c = 0
    for _ in utf8.codes(s) do c = c + 1 end
    return c
  end)
  if ok then return n end
  return #s
end

local function char_em(cp)
  if cp >= 0x1100 and cp <= 0x11FF then return 1.0 end
  if cp >= 0x2E80 then return 1.0 end
  if cp >= 0x0250 and cp <= 0x02FF then return 0.56 end
  if cp >= 0x0370 and cp <= 0x03FF then return 0.62 end
  if cp >= 0x1D400 and cp <= 0x1D7FF then return 0.62 end
  return 0.6
end

local function text_px(s, size)
  if not s or s == "" then return 0 end
  size = size or FS
  local ok, w = pcall(function()
    local acc = 0
    for _, cp in utf8.codes(s) do acc = acc + char_em(cp) end
    return acc
  end)
  if not ok then w = utf8_len(s) * 0.6 end
  return w * size
end

local function xml_escape(s)
  s = s:gsub("&", "&amp;")
  s = s:gsub("<", "&lt;")
  s = s:gsub(">", "&gt;")
  s = s:gsub('"', "&quot;")
  return s
end

-- ------------------------------------------------------------------ parser
local function parse_tree(src)
  local s = src
  local pos = 1
  local n = #s

  local function skip_ws()
    while pos <= n and s:sub(pos, pos):match("%s") do pos = pos + 1 end
  end

  local parse_node

  parse_node = function()
    pos = pos + 1                     -- consume '['
    local start = pos
    while pos <= n and s:sub(pos, pos) ~= "[" and s:sub(pos, pos) ~= "]" do
      pos = pos + 1
    end
    local raw = s:sub(start, pos - 1)
    local node = { raw = raw, children = {} }
    skip_ws()
    while pos <= n and s:sub(pos, pos) == "[" do
      table.insert(node.children, parse_node())
      skip_ws()
    end
    if pos <= n and s:sub(pos, pos) == "]" then pos = pos + 1 end

    -- optional id for an explicitly drawn line: [DP the mouse]{=obj}
    -- (`{=id}` rather than `{#id}`: pandoc reads `[text]{#id}` as a span and
    -- drops the brackets, which would destroy the tree structure)
    if pos <= n and s:sub(pos, pos) == "{" then
      local id = s:match("^{=([%w%-_%.]+)}", pos)
      if id then
        node.ids = node.ids or {}
        table.insert(node.ids, id)
        pos = pos + #id + 3
      end
    end
    return node
  end

  local roots = {}
  skip_ws()
  while pos <= n do
    if s:sub(pos, pos) == "[" then
      table.insert(roots, parse_node())
    else
      pos = pos + 1
    end
    skip_ws()
  end
  return roots
end

-- A label is split into parts so that an index may sit on the head
-- (`DP_i the mouse`) or on a trace (`DP t_i`): see the header comment.
local function analyse(node)
  local l = node.raw:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")

  local judg = ""
  local j = l:match("^([%*%?%%#!]+)%s+")
  if j then
    judg = j
    l = l:sub(#j + 1):gsub("^%s+", "")
  end

  local sup = nil
  l = l:gsub("%^%{(.-)}", function(x) sup = x; return "" end)
  l = l:gsub("%s+$", "")

  local parts = {}
  for tok in l:gmatch("%S+") do
    local b, i = tok:match("^(.-)_([%w%.]+)$")
    if b and b ~= "" then
      table.insert(parts, { text = b, idx = i })
    else
      table.insert(parts, { text = tok })
    end
  end

  if #parts == 0 then
    table.insert(parts, { text = "∅" })
  end

  node.judg = judg
  node.parts = parts
  node.sup = sup
end

-- ------------------------------------------------------------------ layout
local function measure(node)
  local w = text_px(node.judg .. (node.judg ~= "" and " " or ""))
  for _, p in ipairs(node.parts) do
    w = w + text_px(p.text) + 0.3 * FS
    if p.idx then w = w + text_px(p.idx, FS * 0.7) end
  end
  w = w + text_px(node.sup or "", FS * 0.65) + 0.35 * FS
  node.lw = w          -- width of the label itself, for arrow clearance

  -- the same label without the slack, for where a line may stop
  local txt = node.judg .. (node.judg ~= "" and " " or "")
  for i, p in ipairs(node.parts) do
    if i > 1 then txt = txt .. " " end
    txt = txt .. p.text
    if p.idx then txt = txt .. p.idx end
  end
  node.tw = text_px(txt) + text_px(node.sup or "", FS * 0.65)
  if #node.children == 0 then
    node.w = w
  else
    local sum = 0
    for _, c in ipairs(node.children) do
      measure(c)
      sum = sum + c.w
    end
    sum = sum + GAP * (#node.children - 1)
    node.w = math.max(w, sum)
  end
end

local function place(node, left, depth, acc)
  node.depth = depth
  node.cx = left + node.w / 2
  node.cy = depth * LEVEL + FS
  table.insert(acc, node)
  if #node.children > 0 then
    local total = 0
    for _, c in ipairs(node.children) do total = total + c.w end
    total = total + GAP * (#node.children - 1)
    local x = left + (node.w - total) / 2
    for _, c in ipairs(node.children) do
      place(c, x, depth + 1, acc)
      x = x + c.w + GAP
    end
    node.cx = (node.children[1].cx + node.children[#node.children].cx) / 2
  end
end

local function build_layout(roots)
  local total, maxdepth = 0, 0
  for i, r in ipairs(roots) do
    measure(r)
    total = total + r.w
    if i > 1 then total = total + GAP * 2 end
  end
  local nodes = {}
  local x = 0
  for i, r in ipairs(roots) do
    place(r, x, 0, nodes)
    x = x + r.w + GAP * 2
  end
  for _, nd in ipairs(nodes) do
    if nd.depth > maxdepth then maxdepth = nd.depth end
  end
  return {
    nodes = nodes,
    width = math.max(total, 1),
    height = (maxdepth + 1) * LEVEL + 0.4 * FS,
  }
end

local function drawable_nodes(layout)
  local out = {}
  for _, nd in ipairs(layout.nodes) do
    if nd.cy + MARGIN <= layout.height + LEVEL then table.insert(out, nd) end
  end
  return out
end

-- ------------------------------------------------------------------- lines
-- `lines="obj -> cp; t-obj -> dp-obj dashed; a -- b"`: one entry per `;`.
-- `->` puts an arrowhead on the second node, `--` draws a plain line; the
-- word `dashed` after the second id makes the line dashed.
local function parse_lines(spec)
  local out = {}
  if not spec then return out end
  for entry in spec:gmatch("[^;]+") do
    entry = entry:gsub("^%s+", ""):gsub("%s+$", "")
    local from, op, to, rest = entry:match("^(%S+)%s*(%-+>?)%s*(%S+)%s*(.-)$")
    if from and to then
      table.insert(out, {
        from = from,
        to = to,
        arrow = op:sub(-1) == ">",
        dashed = rest:find("dashed") ~= nil,
      })
    end
  end
  return out
end

-- Resolve the ids to nodes; anything that does not match is reported back so
-- that the caller can warn instead of dropping the line silently.
local function collect_lines(layout, specs)
  local by_id = {}
  for _, nd in ipairs(layout.nodes) do
    for _, id in ipairs(nd.ids or {}) do by_id[id] = nd end
  end

  local lines, missing = {}, {}
  for _, spec in ipairs(specs) do
    local from, to = by_id[spec.from], by_id[spec.to]
    if from and to then
      -- a node joined to itself would be a zero-length stroke: draw nothing
      if from ~= to then
        table.insert(lines, {
          from = from, to = to,
          arrow = spec.arrow, dashed = spec.dashed,
        })
      end
    else
      -- report whichever end is the one that does not exist
      table.insert(missing, from and spec.to or spec.from)
    end
  end
  return lines, missing
end

-- ------------------------------------------------------------------ svg
local function svg_text_node(nd)
  local out = {}
  if nd.judg ~= "" then
    table.insert(out, xml_escape(nd.judg) .. " ")
  end
  for i, p in ipairs(nd.parts) do
    if i > 1 then table.insert(out, " ") end
    table.insert(out, xml_escape(p.text))
    if p.idx then
      table.insert(out, string.format(
        '<tspan dy="%.1f" font-size="%.1f">%s</tspan>',
        FS * 0.28, FS * 0.7, xml_escape(p.idx)))
      table.insert(out, string.format('<tspan dy="%.1f"></tspan>', -FS * 0.28))
    end
  end
  if nd.sup then
    table.insert(out, string.format(
      '<tspan dy="%.1f" font-size="%.1f">%s</tspan>',
      -FS * 0.42, FS * 0.65, xml_escape(nd.sup)))
  end
  return table.concat(out)
end

-- A route may leave the layout box (an arrow running around the outside of
-- the tree), so the drawing area is the union of the tree and every stroke.
-- Both renderers use it: the SVG for its viewBox, TikZ to decide the scale.
local function drawing_extent(layout, geoms)
  local x0, y0, x1, y1 = 0, 0, layout.width, layout.height
  local function ext(x, y)
    if x < x0 then x0 = x end
    if y < y0 then y0 = y end
    if x > x1 then x1 = x end
    if y > y1 then y1 = y end
  end
  for _, g in ipairs(geoms) do
    ext(g.x1, g.y1)
    local cur = { g.x1, g.y1 }
    for _, seg in ipairs(g.segs) do
      for i = 0, 24 do
        local px, py = cubic_at(cur, seg[1], seg[2], seg[3], i / 24)
        ext(px, py)
      end
      cur = seg[3]
    end
  end
  return x0, y0, x1, y1
end

local function render_svg(layout, lines)
  tid = tid + 1
  local wid = "ling-arrow-" .. tid
  local geoms = line_geometry(layout, lines)
  local x0, y0, x1, y1 = drawing_extent(layout, geoms)

  local W = (x1 - x0) + 2 * MARGIN
  local H = (y1 - y0) + 2 * MARGIN
  local out = {}

  table.insert(out, string.format(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %.0f %.0f" ' ..
    'width="%.0f" height="%.0f" role="img" class="ling-tree-svg">',
    W, H, W, H))

  table.insert(out, string.format(
    '<defs><marker id="%s" viewBox="0 0 10 10" refX="9" refY="5" ' ..
    'markerWidth="7" markerHeight="7" orient="auto-start-reverse">' ..
    '<path d="M 0 0 L 10 5 L 0 10 z" fill="currentColor" stroke="none"/>' ..
    '</marker></defs>', wid))

  local ox = MARGIN - x0
  local oy = MARGIN - y0

  -- branches
  for _, nd in ipairs(layout.nodes) do
    for _, c in ipairs(nd.children) do
      table.insert(out, string.format(
        '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke-width="1"/>',
        nd.cx + ox, nd.cy + oy + FS * 0.38,
        c.cx + ox, c.cy + oy - FS * 0.95))
    end
  end

  -- lines and movement arrows
  for _, g in ipairs(geoms) do
    local d = { string.format("M %.1f %.1f", g.x1 + ox, g.y1 + oy) }
    for _, seg in ipairs(g.segs) do
      table.insert(d, string.format("C %.1f %.1f %.1f %.1f %.1f %.1f",
        seg[1][1] + ox, seg[1][2] + oy,
        seg[2][1] + ox, seg[2][2] + oy,
        seg[3][1] + ox, seg[3][2] + oy))
    end
    table.insert(out, string.format(
      '<path d="%s" stroke-width="1"%s%s/>',
      table.concat(d, " "),
      g.dashed and ' stroke-dasharray="4 3"' or "",
      g.arrow and (' marker-end="url(#' .. wid .. ')"') or ""))
  end

  -- labels
  for _, nd in ipairs(layout.nodes) do
    table.insert(out, string.format(
      '<text x="%.1f" y="%.1f" text-anchor="middle" font-size="%d">%s</text>',
      nd.cx + ox, nd.cy + oy, FS, svg_text_node(nd)))
  end

  table.insert(out, "</svg>")
  return table.concat(out, "\n")
end

-- ------------------------------------------------------------------ tikz
local function tex_escape(s)
  s = s:gsub("\\", "\\textbackslash{}")
  s = s:gsub("([&%%%$#{}])", "\\%1")
  s = s:gsub("~", "\\textasciitilde{}")
  s = s:gsub("%^", "\\textasciicircum{}")
  return s
end

-- glyphs the text font may not carry: set them from maths instead of letting
-- them vanish (an empty head is a real symbol, not a blank)
local TEX_SYMBOLS = {
  ["∅"] = "\\ensuremath{\\varnothing}",
  ["→"] = "\\ensuremath{\\rightarrow}",
  ["⇒"] = "\\ensuremath{\\Rightarrow}",
  ["↔"] = "\\ensuremath{\\leftrightarrow}",
  ["λ"] = "\\ensuremath{\\lambda}",
  ["∀"] = "\\ensuremath{\\forall}",
  ["∃"] = "\\ensuremath{\\exists}",
  ["ι"] = "\\ensuremath{\\iota}",
  ["⸨"] = "\\ensuremath{[[}",
  ["⸩"] = "\\ensuremath{]]}",
}

local function tex_symbols(s)
  for k, v in pairs(TEX_SYMBOLS) do
    s = s:gsub(k, v)
  end
  return s
end

local function tex_label(nd)
  local out = {}
  if nd.judg ~= "" then table.insert(out, tex_escape(nd.judg)) end
  for _, p in ipairs(nd.parts) do
    local s = tex_escape(p.text)
    if p.idx then
      s = s .. "\\textsubscript{" .. tex_escape(p.idx) .. "}"
    end
    table.insert(out, s)
  end
  local s = tex_symbols(table.concat(out, " "))
  if nd.sup then s = s .. "\\textsuperscript{" .. tex_escape(nd.sup) .. "}" end
  return s
end

local function render_tikz(layout, lines)
  local geoms = line_geometry(layout, lines)

  -- the same extent the SVG uses, so a route that runs outside the tree is
  -- paid for in the scale rather than spilling past the text block
  local x0, _, x1 = drawing_extent(layout, geoms)
  local widthe = ((x1 - x0) + 2 * MARGIN) / FS
  local scale = 1
  if widthe > 32 then scale = 32 / widthe end

  local ids = {}
  for i, nd in ipairs(layout.nodes) do ids[nd] = "n" .. i end

  local out = {}
  table.insert(out, string.format(
    "\\begin{tikzpicture}[x=%.3fem,y=%.3fem,baseline=(current bounding box.center)]",
    scale, scale))

  for _, nd in ipairs(layout.nodes) do
    table.insert(out, string.format("  \\node (%s) at (%.2f,%.2f) {%s};",
      ids[nd], (nd.cx + MARGIN) / FS, -(nd.cy + MARGIN) / FS, tex_label(nd)))
  end
  for _, nd in ipairs(layout.nodes) do
    for _, c in ipairs(nd.children) do
      table.insert(out, string.format("  \\draw (%s.south) -- (%s.north);", ids[nd], ids[c]))
    end
  end
  -- same geometry as the SVG renderer, with the control points in em
  local function pt(x, y)
    return string.format("(%.2f,%.2f)", (x + MARGIN) / FS, -(y + MARGIN) / FS)
  end
  for _, g in ipairs(geoms) do
    local opts = (g.arrow and "->," or "") .. (g.dashed and "dashed" or "solid")
    local d = { pt(g.x1, g.y1) }
    for _, seg in ipairs(g.segs) do
      table.insert(d, string.format(".. controls %s and %s .. %s",
        pt(seg[1][1], seg[1][2]), pt(seg[2][1], seg[2][2]), pt(seg[3][1], seg[3][2])))
    end
    table.insert(out, string.format("  \\draw[%s] %s;", opts, table.concat(d, " ")))
  end
  table.insert(out, "\\end{tikzpicture}")
  return table.concat(out, "\n")
end

-- ------------------------------------------------------------------ main
local ensured_preamble = false

local function ensure_tikz()
  if ensured_preamble then return end
  ensured_preamble = true
  pcall(function()
    quarto.doc.include_text("in-header", "\\usepackage{tikz}")
  end)
end

function Div(el)
  if not el.classes:includes("tree") then return nil end

  local src = pandoc.utils.stringify(el.content)
  local roots = parse_tree(src)
  if #roots == 0 then return nil end

  for _, r in ipairs(roots) do
    -- annotate every node
    local function walk(n)
      analyse(n)
      for _, c in ipairs(n.children) do walk(c) end
    end
    walk(r)
  end

  local layout = build_layout(roots)
  local lines, missing = collect_lines(layout, parse_lines(el.attributes["lines"]))
  for _, id in ipairs(missing) do
    pcall(function()
      quarto.log.warning("tree: no node with id '" .. id .. "'")
    end)
  end

  if quarto.doc.isFormat("latex") or quarto.doc.isFormat("pdf") then
    ensure_tikz()
    return pandoc.RawBlock("latex",
      "\\begin{center}\n" .. render_tikz(layout, lines) .. "\n\\end{center}")
  end

  if quarto.doc.isFormat("html") or quarto.doc.isFormat("revealjs") then
    return pandoc.Div(
      { pandoc.RawBlock("html", render_svg(layout, lines)) },
      pandoc.Attr(el.identifier, { "ling-tree" }))
  end

  -- fallback: show the bracketed source
  return pandoc.Div(
    { pandoc.CodeBlock(src, pandoc.Attr("", { "ling-tree-source" })) },
    pandoc.Attr(el.identifier, { "ling-tree" }))
end
