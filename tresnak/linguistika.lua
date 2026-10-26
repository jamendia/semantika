-- tresnak/linguistika.lua
-- Pandoc filter: linguistic trees and glosses.
--
--   ::: {.tree #id}
--   [P [IS ...] [AS ...]]
--   :::
--     -> LaTeX: \begin{forest}...\end{forest}
--     -> HTML:  <img src="assets/arbolak/<id>.svg">
--
--   ::: {.gloss #id}
--   original line
--   gloss line
--   translation line
--   :::
--     -> LaTeX: \begingl ... \endgl  (ExPex)
--     -> HTML:  <div class="gloss"> with three lines

local function is_latex()
  return FORMAT:match("latex") ~= nil or FORMAT:match("pdf") ~= nil
end

local function is_html()
  return FORMAT:match("html") ~= nil
end

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
    local content = pandoc.utils.stringify(el):gsub("^%s+", ""):gsub("%s+$", "")
    if is_latex() then
      local latex = "\\begin{forest}\n" .. content .. "\n\\end{forest}"
      return pandoc.RawBlock("latex", latex)
    elseif is_html() then
      local src = "assets/arbolak/" .. id .. ".svg"
      local alt = "Zuhaitz sintaktikoa: " .. id
      local img = pandoc.Image({pandoc.Str(alt)}, src, alt)
      return pandoc.Para({img})
    end
  end

  if el.classes:includes("gloss") then
    local lines = div_lines(el)
    local orig = lines[1] or ""
    local gloss = lines[2] or ""
    local trans = lines[3] or ""
    if is_latex() then
      local latex = "\\begingl\n"
      if orig ~= "" then latex = latex .. "\\gla " .. orig .. " //\n" end
      if gloss ~= "" then latex = latex .. "\\glb " .. gloss .. " //\n" end
      if trans ~= "" then latex = latex .. "\\glft " .. trans .. " //\n" end
      latex = latex .. "\\endgl"
      return pandoc.RawBlock("latex", latex)
    elseif is_html() then
      local html = "<div class=\"gloss\">\n"
      if orig ~= "" then html = html .. "<div class=\"gloss-line gloss-orig\">" .. orig .. "</div>\n" end
      if gloss ~= "" then html = html .. "<div class=\"gloss-line gloss-gloss\">" .. gloss .. "</div>\n" end
      if trans ~= "" then html = html .. "<div class=\"gloss-line gloss-trans\">" .. trans .. "</div>\n" end
      html = html .. "</div>"
      return pandoc.RawBlock("html", html)
    end
  end

  return nil
end
