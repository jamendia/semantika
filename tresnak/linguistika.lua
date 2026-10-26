-- tresnak/linguistika.lua
-- Pandoc iragazkia: hizkuntzalaritzako zuhaitzak eta glossak (HTML).
--
-- Zuhaitza:
--   ::: {.tree #id}
--   [P [IS ...] [AS ...]]
--   :::
--   -> <img src="assets/arbolak/<id>.svg">
--   SVGa tresnak/arbolak.py-k sortzen du (Forest -> SVG), eta biltegian
--   gordetzen da. Aldatu zuhaitza bada, exekutatu: python tresnak/arbolak.py
--
-- Glossa (hizkuntza arrotzetako adibideentzat soilik; euskarazkoak ez):
--   ::: {.gloss #id}
--   jatorrizko lerroa
--   glossa lerroa
--   itzulpen lerroa
--   :::
--   -> <div class="gloss"> hiru lerrorekin

local function is_html()
  return FORMAT:match("html") ~= nil
end

-- Div baten lerroak lortu, SoftBreak/LineBreak-ak errespetatuz.
local function div_lines(el)
  local out = {}
  local current = ""
  for _, block in ipairs(el.content) do
    if block.t == "Para" or block.t == "Plain" then
      for _, inline in ipairs(block.content) do
        if inline.t == "SoftBreak" or inline.t == "LineBreak" then
          local trimmed = current:match("^%s*(.-)%s*$")
          if trimmed ~= "" then table.insert(out, trimmed) end
          current = ""
        else
          current = current .. pandoc.utils.stringify(inline)
        end
      end
      local trimmed = current:match("^%s*(.-)%s*$")
      if trimmed ~= "" then table.insert(out, trimmed) end
      current = ""
    elseif block.t == "RawBlock" then
      for line in block.text:gmatch("[^\r\n]+") do
        local t = line:match("^%s*(.-)%s*$")
        if t ~= "" then table.insert(out, t) end
      end
    end
  end
  if current ~= "" then
    local t = current:match("^%s*(.-)%s*$")
    if t ~= "" then table.insert(out, t) end
  end
  return out
end

function Div(el)
  if el.classes:includes("tree") then
    local id = el.identifier or ""
    local src = "assets/arbolak/" .. id .. ".svg"
    local alt = "Zuhaitz sintaktikoa: " .. id
    local img = pandoc.Image({pandoc.Str(alt)}, src, alt)
    return pandoc.Para({img})
  end

  if el.classes:includes("gloss") then
    local lines = div_lines(el)
    local orig = lines[1] or ""
    local gloss = lines[2] or ""
    local trans = lines[3] or ""
    local html = "<div class=\"gloss\">\n"
    if orig ~= "" then html = html .. "<div class=\"gloss-line gloss-orig\">" .. orig .. "</div>\n" end
    if gloss ~= "" then html = html .. "<div class=\"gloss-line gloss-gloss\">" .. gloss .. "</div>\n" end
    if trans ~= "" then html = html .. "<div class=\"gloss-line gloss-trans\">" .. trans .. "</div>\n" end
    html = html .. "</div>"
    return pandoc.RawBlock("html", html)
  end

  return nil
end
