--[==[
  tree-lines.lua -- where the lines of a syntax tree go

  filter-tree.lua parses and lays out a tree, then hands the finished layout
  and the list of lines to draw to this module, which answers one question:
  for each line, where does the stroke start and end, and what curve does it
  follow.  Nothing here knows about pandoc -- it takes plain tables of numbers
  and returns plain tables of numbers -- so it can be exercised on its own.

  A layout is `{ width, height, nodes = { ... } }` where each node carries
  `cx`, `cy` (its label's baseline), `lw` (the width allotted to the label)
  and `tw` (the width of the label itself); a line is
  `{ from = node, to = node, arrow = bool, dashed = bool }`.

  The geometry returned for a line is
  `{ x1, y1, segs = { { c1, c2, end }, ... }, arrow, dashed }`, with `x1, y1`
  the start of the stroke in layout coordinates and each segment a cubic
  Bezier ending at `end`.
]==]

local M = {}

-- Layout metrics, set once by configure() so that nothing downstream has to
-- thread them through every call.
local FS, LEVEL, TEXT_TOP, TEXT_BOT, CLEAR

function M.configure(fs, level)
  FS = fs
  LEVEL = level
  -- A label sits from 0.74em above its baseline (cap height) to 0.30em below
  -- it (descenders); a line stops one CLEAR short of that box.
  TEXT_TOP = 0.74 * FS
  TEXT_BOT = 0.30 * FS
  CLEAR = 0.30 * FS
end

local function cubic_at(p0, c1, c2, p1, t)
  local u = 1 - t
  return u * u * u * p0[1] + 3 * u * u * t * c1[1] + 3 * u * t * t * c2[1] + t * t * t * p1[1],
         u * u * u * p0[2] + 3 * u * u * t * c1[2] + 3 * u * t * t * c2[2] + t * t * t * p1[2]
end
M.cubic_at = cubic_at

local function text_box(nd, pad)
  pad = pad or 0
  local hw = (nd.tw or nd.lw or nd.w or 0) / 2 + pad
  return { nd.cx - hw, nd.cy - TEXT_TOP - pad, nd.cx + hw, nd.cy + TEXT_BOT + pad }
end

local function label_box(nd)
  return text_box(nd, 0.14 * FS)
end

-- A line is routed from the optical centre of one label to the centre of
-- the other; the stroke is then trimmed back to the edge of each text box,
-- so what is drawn starts and stops just clear of the glyphs, on whichever
-- side the curve leaves one label and reaches the other.
local function line_anchors(a, b)
  return { a.cx, a.cy - 0.2 * FS }, { b.cx, b.cy - 0.2 * FS }
end

-- Several lines may meet at one node.  Each of them gets its own point on
-- the label's edge, fanned out around the centre, so that two arrowheads
-- never land on top of each other and the lines read as going somewhere
-- distinct instead of merging into one blob.
local function fan_offsets(lines)
  local arriving, leaving = {}, {}
  for _, ln in ipairs(lines) do
    arriving[ln.to] = (arriving[ln.to] or 0) + 1
    leaving[ln.from] = (leaving[ln.from] or 0) + 1
  end
  return arriving, leaving
end

local function fan_offset(node, index, count)
  if count <= 1 then return 0 end
  local width = node.tw or node.lw or 0
  local step = math.min(1.2 * FS, width / (count + 0.3))
  local off = (index - (count + 1) / 2) * step
  local limit = width * 0.34
  return math.max(-limit, math.min(limit, off))
end

-- Two nodes on one level are joined side by side, from the edge of one
-- allotted box to the edge of the other, so that neighbouring siblings are
-- linked across the whole gap between them.
local function side_anchors(a, b)
  local sign = (a.cx <= b.cx) and 1 or -1
  local y = -0.24 * FS
  return { a.cx + sign * ((a.lw or a.w or 0) / 2 + 0.07 * FS), a.cy + y },
         { b.cx - sign * ((b.lw or b.w or 0) / 2 + 0.07 * FS), b.cy + y }
end

-- How many sampled points of a route fall inside a label box.  Routes are
-- ranked by this, so a line takes the emptiest path it can find instead of
-- crossing a label whenever the first guess happens to be blocked.  A route
-- is a list of cubic segments, each `{ control1, control2, end }`.
local function hits(boxes, p0, route)
  local n = 0
  local cur = p0
  for _, seg in ipairs(route) do
    for i = 0, 64 do
      local u = i / 64
      local x, y = cubic_at(cur, seg[1], seg[2], seg[3], u)
      for _, b in ipairs(boxes) do
        if x > b[1] and x < b[3] and y > b[2] and y < b[4] then
          n = n + 1
          break
        end
      end
    end
    cur = seg[3]
  end
  return n
end

-- distance from a point to a segment (used to keep lines off the branches)
local function seg_dist(p, s)
  local vx, vy = s[3] - s[1], s[4] - s[2]
  local wx, wy = p[1] - s[1], p[2] - s[2]
  local d2 = vx * vx + vy * vy
  local t = 0
  if d2 > 0 then t = math.max(0, math.min(1, (wx * vx + wy * vy) / d2)) end
  local dx, dy = wx - t * vx, wy - t * vy
  return math.sqrt(dx * dx + dy * dy)
end

local function route_len(p0, route)
  local n, cur = 0, p0
  for _, seg in ipairs(route) do
    local dx, dy = seg[3][1] - cur[1], seg[3][2] - cur[2]
    n = n + math.sqrt(dx * dx + dy * dy)
    cur = seg[3]
  end
  return n
end

-- How often a route brushes past a branch line.  Lines are allowed to cross
-- the structure where they must, but the emptiest route is preferred.
local function crosses(branches, p0, route)
  local n = 0
  local cur = p0
  for _, seg in ipairs(route) do
    for i = 0, 48 do
      local x, y = cubic_at(cur, seg[1], seg[2], seg[3], i / 48)
      for _, b in ipairs(branches) do
        if seg_dist({ x, y }, b) < 0.18 * FS then
          n = n + 1
          break
        end
      end
    end
    cur = seg[3]
  end
  return n
end

local function pt_lerp(a, b, t)
  return { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t }
end

-- de Casteljau: the same cubic, cut at `t`.  Returns the head as a segment
-- ending at the cut point, the cut point itself, and the tail from there.
local function split_cubic(p, s, t)
  local q1 = pt_lerp(p, s[1], t)
  local q2 = pt_lerp(s[1], s[2], t)
  local q3 = pt_lerp(s[2], s[3], t)
  local r1 = pt_lerp(q1, q2, t)
  local r2 = pt_lerp(q2, q3, t)
  local cut = pt_lerp(r1, r2, t)
  return { q1, r1, cut }, cut, { r2, q3, s[3] }
end

local function inside(p, b)
  return p[1] > b[1] and p[1] < b[3] and p[2] > b[2] and p[2] < b[4]
end

-- Stop the stroke before it reaches the glyphs: if the route enters the
-- target's text box, it is cut where it first does so, so the line (and its
-- arrowhead) ends just outside the label however it approaches.
local function stop_short(p0, route, box)
  local cur = p0
  local enter
  for si, seg in ipairs(route) do
    local was = inside(cur, box)
    local prev_t = 0
    for j = 1, 160 do
      local t = j / 160
      local x, y = cubic_at(cur, seg[1], seg[2], seg[3], t)
      local now = inside({ x, y }, box)
      if now and not was then enter = { si, prev_t } end
      if not now then prev_t = t end
      was = now
    end
    cur = seg[3]
  end
  if not enter then return p0, route end
  if enter[2] <= 0 then return p0, route end

  local head, prev = {}, p0
  for i = 1, enter[1] - 1 do
    table.insert(head, route[i])
    prev = route[i][3]
  end
  local sub = split_cubic(prev, route[enter[1]], enter[2])
  table.insert(head, sub)
  return p0, head
end

-- The mirror image at the start: the stroke begins where the curve leaves
-- the source's own label, not at the label's centre.
local function cut_tail(p0, route, box)
  if not inside(p0, box) then return p0, route end
  local cur = p0
  for si, seg in ipairs(route) do
    for j = 1, 160 do
      local t = j / 160
      local x, y = cubic_at(cur, seg[1], seg[2], seg[3], t)
      if not inside({ x, y }, box) then
        local _, cut, tail = split_cubic(cur, seg, t)
        local rest = { tail }
        for i = si + 1, #route do table.insert(rest, route[i]) end
        return cut, rest
      end
    end
    cur = seg[3]
  end
  return p0, route
end

-- a quadratic bow, written as its equivalent cubic, as a one-segment route
local function bow(p0, p1, c)
  return { {
    { p0[1] + 2 / 3 * (c[1] - p0[1]), p0[2] + 2 / 3 * (c[2] - p0[2]) },
    { p1[1] + 2 / 3 * (c[1] - p1[1]), p1[2] + 2 / 3 * (c[2] - p1[2]) },
    { p1[1], p1[2] },
  } }
end

-- Last resort for two labels that almost touch: a short straight link
-- between the edges that face each other.
local function edge_link(a, b)
  local dx = b.cx - a.cx
  local sgn = (dx >= 0) and 1 or -1
  local ha = (a.lw or a.w or 0) / 2 + CLEAR
  local hb = (b.lw or b.w or 0) / 2 + CLEAR
  local p = { a.cx + sgn * ha, a.cy - 0.2 * FS }
  local q = { b.cx - sgn * hb, b.cy - 0.2 * FS }
  return p, { {
    { p[1] + (q[1] - p[1]) / 3, p[2] + (q[2] - p[2]) / 3 },
    { p[1] + 2 * (q[1] - p[1]) / 3, p[2] + 2 * (q[2] - p[2]) / 3 },
    q,
  } }
end

-- Every line is one arc of the same family: a bow to the west of the chord,
-- whose bulge grows with the distance between the two nodes.  A line only
-- departs from that shape when the standard arc would run through a label.
function M.geometry(layout, lines)
  local all = {}
  for _, nd in ipairs(layout.nodes) do all[nd] = label_box(nd) end

  local branches = {}
  for _, nd in ipairs(layout.nodes) do
    for _, c in ipairs(nd.children) do
      table.insert(branches, { nd.cx, nd.cy + FS * 0.38, c.cx, c.cy - FS * 0.95 })
    end
  end

  local arriving, leaving = fan_offsets(lines)
  local arrived, left = {}, {}

  local out = {}
  for _, ln in ipairs(lines) do
    local p0, p1 = line_anchors(ln.from, ln.to)
    left[ln.from] = (left[ln.from] or 0) + 1
    arrived[ln.to] = (arrived[ln.to] or 0) + 1
    p0[1] = p0[1] + fan_offset(ln.from, left[ln.from], leaving[ln.from])
    p1[1] = p1[1] + fan_offset(ln.to, arrived[ln.to], arriving[ln.to])
    local dx, dy = p1[1] - p0[1], p1[2] - p0[2]
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1 then len = 1 end
    local mid = { (p0[1] + p1[1]) / 2, (p0[2] + p1[2]) / 2 }
    local same_row = math.abs(dy) < LEVEL * 0.5

    -- the two labels the line joins are not obstacles: the stroke is trimmed
    -- back to their edges once the route is chosen
    local boxes = {}
    for nd, b in pairs(all) do
      if nd ~= ln.from and nd ~= ln.to then table.insert(boxes, b) end
    end

    local straight = { {
      { p0[1] + dx / 3, p0[2] + dy / 3 },
      { p0[1] + 2 * dx / 3, p0[2] + 2 * dy / 3 },
      { p1[1], p1[2] },
    } }

    local ux, uy = dx / len, dy / len
    local nx, ny = -uy, ux
    if nx > 0 then nx, ny = -nx, -ny end
    local base = math.max(1.05 * FS, math.min(2.2 * FS, 0.14 * len))

    -- The line is an arc bowed to the west.  An arrow marks a landing site,
    -- so it leaves and arrives vertically and its head points straight into
    -- the label; a plain link leaves and arrives along the chord between the
    -- two nodes.
    local function arc(sign, k)
      local ay = uy * len * 0.4
      if ln.arrow then
        local off = sign * base * k * 2.0    -- the bow rides on one control point
        return { {
          { p0[1] + nx * off, p0[2] + ay + ny * off },
          { p1[1] + nx * off * 0.18, p1[2] - ay + ny * off * 0.18 },
          { p1[1], p1[2] },
        } }
      end
      local off = sign * base * k * 1.33     -- control offset for a bulge of base*k
      local ax = ux * len * 0.4
      return { {
        { p0[1] + ax + nx * off, p0[2] + ay + ny * off },
        { p1[1] - ax + nx * off, p1[2] - ay + ny * off },
        { p1[1], p1[2] },
      } }
    end

    local candidates = {}
    if same_row then
      -- neighbours on one level: a straight run between the two boxes, or a
      -- shallow arc above or below it when something stands in the way
      p0, p1 = side_anchors(ln.from, ln.to)
      table.insert(candidates, { {
        { p0[1] + (p1[1] - p0[1]) / 3, p0[2] + (p1[2] - p0[2]) / 3 },
        { p0[1] + 2 * (p1[1] - p0[1]) / 3, p0[2] + 2 * (p1[2] - p0[2]) / 3 },
        { p1[1], p1[2] },
      } })
      for _, k in ipairs({ 1.0, 1.9 }) do
        table.insert(candidates, bow(p0, p1, { mid[1], mid[2] - k * FS }))
        table.insert(candidates, bow(p0, p1, { mid[1], mid[2] + k * FS }))
      end
    else
      for _, k in ipairs({ 1.0, 1.6, 2.3, 3.2 }) do
        table.insert(candidates, arc(1, k))
      end
      for _, k in ipairs({ 1.0, 1.7, 2.6 }) do
        table.insert(candidates, arc(-1, k))
      end

      -- still blocked: drop from the start and come in along the target's
      -- own row from the west
      for _, dxs in ipairs({ 0, -1.2, -2.4 }) do
        table.insert(candidates, { {
          { p0[1] + dxs * FS, p0[2] + 0.8 * (p1[2] - p0[2]) },
          { p1[1] - 1 * FS + dxs * FS, p1[2] },
          { p1[1], p1[2] },
        } })
      end

      -- long movements in a dense tree: leave on the outside, run below the
      -- tree, and come up into the target from underneath
      local bottom = layout.height + 1.0 * FS
      local right = layout.width + 0.8 * FS
      table.insert(candidates, {
        { { p0[1] + 1.4 * FS, p0[2] }, { right + 0.6 * FS, bottom - 0.9 * FS },
          { right + 1.0 * FS, bottom } },
        { { (right + p1[1]) / 2, bottom + 1.2 * FS }, { p1[1] - 2.0 * FS, bottom },
          { p1[1], bottom - 0.9 * FS } },
        { { p1[1], bottom - 1.6 * FS }, { p1[1], p1[2] + 1.4 * FS }, { p1[1], p1[2] } },
        far = true,      -- only when nothing nearer gets through
      })

      table.insert(candidates, straight)
    end

    -- a line never crosses a label if any candidate avoids it; among the
    -- routes that are equally clean, the one that brushes the fewest branches
    -- wins, and the shortest of those
    local candHits = {}
    local cleanest = math.huge
    for ci, cand in ipairs(candidates) do
      candHits[ci] = hits(boxes, p0, cand)
      cleanest = math.min(cleanest, candHits[ci])
    end

    -- the outside route is a way out of a blocked tree, not a prettier line:
    -- it is only weighed up when no nearer route is clean
    local chosen, best, far, farScore
    for ci, cand in ipairs(candidates) do
      if candHits[ci] == cleanest then
        local score = crosses(branches, p0, cand) * 0.04
          + route_len(p0, cand) * 0.0005
        if cand.far then
          if not farScore or score < farScore then far, farScore = cand, score end
        elseif not best or score < best then
          chosen, best = cand, score
        end
      end
    end
    chosen = chosen or far or candidates[1]

    if not same_row then
      -- nothing is drawn inside a label: both ends are pulled back to the
      -- edge of the text box, just short of the glyphs
      p0, chosen = cut_tail(p0, chosen, text_box(ln.from, CLEAR * 0.45))
      p0, chosen = stop_short(p0, chosen, text_box(ln.to, CLEAR * 0.45))

      -- labels that almost touch would leave nothing in between: join the
      -- two facing edges with a short straight link instead
      local endp = p0
      for _, s in ipairs(chosen) do endp = s[3] end
      if #chosen == 0
        or math.abs(endp[1] - p0[1]) + math.abs(endp[2] - p0[2]) < 0.5 * FS then
        p0, chosen = edge_link(ln.from, ln.to)
      end
    end

    table.insert(out, {
      x1 = p0[1], y1 = p0[2], segs = chosen,
      arrow = ln.arrow, dashed = ln.dashed,
    })
  end
  return out
end

return M
