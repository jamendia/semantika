-- tresnak/linguistika.lua
-- Pandoc iragazkia: hizkuntzalaritzako adibideak eta glossak.
--
-- HTML (lehenetsia):
--   ::: {#exm-...}  -> Quarto crossref-ek errendatzen du (theorem example);
--                      tresnak/ostprozesatu.py-k zenbakitzen du gero,
--                      liburu osoan (1), (2), (3)...
--   ::: {.gloss}    -> <table class="gloss-table"> hitzez hitz lerrokatuta
--                      (jatorrizkoa / glossa / itzulpena)
--
-- LaTeX (PDF):
--   ::: {#exm-...}  -> \ex / \pex + \label{...} + \xe  (ExPex; zenbakitze
--                      globala ExPex beraren esku, (1), (2), (3)...)
--                      Azpizatiak (a., b., c.) pandoc-en OrderedList gisa
--                      heldu eta \a errepikatuz sortzen dira.
--   ::: {.gloss}    -> \begingl \gla/\glb/\glft ... \endgl (ExPex)
--
-- Glossa-forma bi:
--   * hiru lerro soilak (hemen): hitz-mailako lerrokatzea, ohiko kasua.
--   * barnean pipe-taula bat: morfema-zutabeak behar dituenerako.
--     Orduan `_extensions/linguistics`-eko filter-gloss.lua-k hartzen du
--     (HTML: `.ling-gloss` taula; LaTeX: tabular). Hemen ez dugu ukitzen,
--     bestela taula hutsa sortzen da isilean.
--
-- Zuhaitzak (`{.tree}`) eta deribazio semantikoak (`{.deriv}`) ez dira hemen
-- kudeatzen: _extensions/linguistics luzapenaren ardura dira (SVG/TikZ).
--
-- LaTeX-en #exm- div-ak Quarto crossref-ek jaso ditzan, hau da, gure
-- iragazkiak identifikatzailearekin ikus ditzan, `quarto._quarto.ast.walk`
-- erabili behar da: crossref-ek bere div-ak "custom AST" nodo bihurtzen ditu
-- quarto-pre fasean, eta ohiko ibilketak anonimo ikusten ditu. ast.walk-ek,
-- aldiz, nodo horiek Div gisa pasatzen ditu, identifikatzailea berreskuratuta.
--
-- Glossa hizkuntza arrotzetako adibideentzat soilik; euskarazkoak ez.

local ok, quarto = pcall(require, "quarto")

local function is_latex()
  return FORMAT:match("latex") ~= nil
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

-- Bloke zerrenda LaTeXera errendatu (math, enfasi... pandoc-ek berekiz).
local function to_latex(blocks)
  local doc = pandoc.Pandoc(blocks)
  local s = pandoc.write(doc, "latex")
  return s:gsub("%s+$", "")
end

-- Glossako testua LaTeXerako ihes egin. `div_lines`-ek testu soila ematen du
-- (stringify), beraz karaktere bereziak literalak dira. Pasa bakarrean
-- egiten da, `\textbackslash{}`-en giltzak berriz ez ihes egiteko.
local TEX_ESCAPES = {
  ["\\"] = "\\textbackslash{}",
  ["{"] = "\\{",
  ["}"] = "\\}",
  ["$"] = "\\$",
  ["&"] = "\\&",
  ["#"] = "\\#",
  ["%"] = "\\%",
  ["_"] = "\\_",
  ["~"] = "\\textasciitilde{}",
  ["^"] = "\\textasciicircum{}",
}

local function tex_escape(s)
  return (s:gsub("[\\{}$&#%%_~^]", function(c) return TEX_ESCAPES[c] end))
end

-- Morfema gramatikalak letra larri txikiz: "read.PST" -> "read.\textsc{PST}".
-- HTMLko `.gloss-abbr` estiloa islatzen du, bi formatuek itxura bera izan
-- dezaten (aurretik PDFak "PST" letra larri arruntez erakusten zuen).
local function gloss_word_tex(w)
  local base, abbr = w:match("^(.-)%.([%u%d]+)$")
  if base and base ~= "" then
    return tex_escape(base) .. ".\\textsc{" .. abbr .. "}"
  end
  return tex_escape(w)
end

local function gloss_line_tex(line)
  local out = {}
  for w in line:gmatch("%S+") do
    table.insert(out, gloss_word_tex(w))
  end
  return table.concat(out, " ")
end

-- Glossa div-a -> ExPex blokea. Lerro bakoitzak // amaiera behar du
-- (ExPex-ek argumentu iheskorra hartzen du bestela).
local function gloss_latex(lines)
  local parts = {}
  if lines[1] and lines[1] ~= "" then
    table.insert(parts, "\\gla " .. gloss_line_tex(lines[1]) .. " //")
  end
  if lines[2] and lines[2] ~= "" then
    table.insert(parts, "\\glb " .. gloss_line_tex(lines[2]) .. " //")
  end
  if lines[3] and lines[3] ~= "" then
    table.insert(parts, "\\glft " .. tex_escape(lines[3]) .. " //")
  end
  return "\\begingl\n" .. table.concat(parts, "\n") .. "\n\\endgl"
end

-- Pipe-taula bat badu, glossa morfema-zutabekoa da eta luzapenaren
-- filter-gloss.lua-k hartu behar du. Hemen ez ukitu: `div_lines`-ek ez luke
-- lerro bakar bat ere irakurriko eta taula huts bat sortuko litzateke.
local function has_table(el)
  for _, block in ipairs(el.content) do
    if block.t == "Table" then return true end
  end
  return false
end

-- Adibide div-a (#exm-...) -> ExPex (\ex edo \pex).
local function example_latex(el)
  local id = el.identifier
  local label = ""
  if id ~= "" then
    label = "\\label{" .. id .. "}"
  end

  -- Barneko .gloss div-a bilatu (adibide bakar bat = zenbaki bakarra).
  local gloss_lines = nil
  local body = {}
  for _, block in ipairs(el.content) do
    if block.t == "Div" and block.classes:includes("gloss") and not has_table(block) then
      gloss_lines = div_lines(block)
    else
      table.insert(body, block)
    end
  end

  if gloss_lines then
    return "\\ex" .. label .. "\n" .. gloss_latex(gloss_lines) .. "\n\\xe"
  end

  -- Azpizatidun adibidea: pandoc-en OrderedList (a., b., c...) -> \a errepikatua.
  -- Oharra: \a errepikatzen da azpizati bakoitzarentzat; ExPex-ek berak
  -- handitzen du kontagailua (\b ez da erabiltzen, LaTeX-eko azentuarekin
  -- talka egiten duelako).
  for _, block in ipairs(body) do
    if block.t == "OrderedList" and #block.content > 1 then
      local parts = { "\\pex" .. label }
      for _, item in ipairs(block.content) do
        table.insert(parts, "\\a " .. to_latex(item))
      end
      table.insert(parts, "\\xe")
      return table.concat(parts, "\n")
    end
  end

  -- Adibide bakuna.
  return "\\ex" .. label .. "\n" .. to_latex(body) .. "\n\\xe"
end

-- LaTeX-erako Div maneiatzailea (quarto._quarto.ast.walk bidez exekutatzen da,
-- crossref-aren custom nodoak ikusgai daudela).
local function latex_div(el)
  -- Adibidea -> ExPex (zenbakitze globala).
  if el.identifier:match("^exm%-") then
    return pandoc.RawBlock("latex", example_latex(el))
  end

  -- Glossa (adibide baten barnean egon edo ez). Pipe-taula bada, luzapenak
  -- hartzen du (ikus hasierako oharra).
  if el.classes:includes("gloss") and not has_table(el) then
    return pandoc.RawBlock("latex", gloss_latex(div_lines(el)))
  end

  return nil
end

function Div(el)
  if is_latex() then
    -- LaTeX: ast.walk-ek kudeatzen du (ikus Pandoc behean). Hemen ez egin
    -- ezer, bikoiztea ekiditeko; ast.walk erabilgarri ez badago, ordezkoa:
    if not (ok and quarto and quarto._quarto and quarto._quarto.ast
            and quarto._quarto.ast.walk) then
      return latex_div(el)
    end
    return nil
  end

  -- HTML: glossa taula gisa (hitz-mailako lerrokatzea).
  -- Jatorrizko lerroa eta glossa hitzez hitz lotzen dira; itzulpen askea
  -- zutabe osoan zabaltzen da. Pipe-taula bada, luzapenak hartzen du.
  if el.classes:includes("gloss") and not has_table(el) then
    local function escape(s)
      return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
    end
    -- Morfema gramatikalak letra larri txikiz erakusteko: "read.PST" ->
    -- "read.<span class=\"gloss-abbr\">PST</span>". Glossako hitz arruntek
    -- ez dute aldaketarik.
    local function gloss_cell(w)
      local base, abbr = w:match("^(.-)%.([%u%d]+)$")
      if base and base ~= "" then
        return escape(base) .. ".<span class=\"gloss-abbr\">" .. escape(abbr) .. "</span>"
      end
      return escape(w)
    end
    local lines = div_lines(el)
    local orig = lines[1] or ""
    local gloss = lines[2] or ""
    local trans = lines[3] or ""
    local ow, gw = {}, {}
    for w in orig:gmatch("%S+") do table.insert(ow, w) end
    for w in gloss:gmatch("%S+") do table.insert(gw, w) end
    local n = math.max(#ow, #gw)
    local html = {"<table class=\"gloss-table\">\n<tbody>"}
    if n > 0 then
      html[#html + 1] = "<tr class=\"gloss-orig\">"
      for i = 1, n do
        html[#html + 1] = "<td>" .. escape(ow[i] or "") .. "</td>"
      end
      html[#html + 1] = "</tr>\n<tr class=\"gloss-gloss\">"
      for i = 1, n do
        html[#html + 1] = "<td>" .. gloss_cell(gw[i] or "") .. "</td>"
      end
      html[#html + 1] = "</tr>"
    end
    if trans ~= "" then
      html[#html + 1] = "<tr class=\"gloss-trans\"><td colspan=\"" .. n .. "\">"
        .. escape(trans) .. "</td></tr>"
    end
    html[#html + 1] = "</tbody>\n</table>"
    return pandoc.RawBlock("html", table.concat(html, "\n"))
  end

  return nil
end

function Pandoc(doc)
  -- LaTeX: crossref-ek exm div-ak custom AST nodo bihurtzen ditu eta
  -- `quarto` modulua ez dago erabilgarri erabiltzaile-iragazkietan; beraz,
  -- exm div-ak ezin dira hemen jaso. Ordezko bidea tex/aurrea.tex-en dago:
  -- crossref-aren `example` ingurunea ExPex-en \ex/\xe-rekin ordezkatzen da
  -- \AtBeginDocumentean (zenbakitze globala ExPex-en kontagailutik).
  return nil
end
