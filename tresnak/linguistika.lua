-- tresnak/linguistika.lua
-- Pandoc iragazkia: hizkuntzalaritzako adibideak, zuhaitzak eta glossak.
--
-- HTML (lehenetsia):
--   ::: {#exm-...}  -> Quarto crossref-ek errendatzen du (theorem example);
--                      tresnak/ostprozesatu.py-k zenbakitzen du gero,
--                      liburu osoan (1), (2), (3)...
--   ::: {.tree #id} -> <img src="assets/arbolak/<id>.svg">
--                      SVGa tresnak/arbolak.py-k sortzen du (Forest -> SVG),
--                      eta biltegian gordetzen da. Aldatu zuhaitza bada,
--                      exekutatu: python tresnak/arbolak.py
--   ::: {.gloss}    -> <table class="gloss-table"> hitzez hitz lerrokatuta
--                      (jatorrizkoa / glossa / itzulpena)
--
-- LaTeX (PDF):
--   ::: {#exm-...}  -> \ex / \pex + \label{...} + \xe  (ExPex; zenbakitze
--                      globala ExPex beraren esku, (1), (2), (3)...)
--                      Azpizatiak (a., b., c.) pandoc-en OrderedList gisa
--                      heldu eta \a errepikatuz sortzen dira.
--   ::: {.gloss}    -> \begingl \gla/\glb/\glft ... \endgl (ExPex)
--   ::: {.tree #id} -> \begin{forest}...\end{forest}
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

-- Orrialdearen sakonera: dokumentuaren karpeta (QUARTO_DOCUMENT_PATH)
-- proiektu-erroarekin (QUARTO_PROJECT_ROOT) alderatuta. Adibidez,
-- `kapituluak` azpikarpeta -> "../" ; erroko orrialdeak -> "".
-- Oharra: PANDOC_STATE.input_files ez da erabiltzen, Quarto-k pandoc-i
-- fitxategi-temporal bat pasatzen diolako, jatorrizko .qmd-a ez.
local function asset_prefix()
  local doc_dir = os.getenv("QUARTO_DOCUMENT_PATH")
  local root = os.getenv("QUARTO_PROJECT_ROOT")
  if not doc_dir or doc_dir == "" or not root or root == "" then
    return ""
  end
  local function norm(p)
    p = p:gsub("\\", "/")
    p = p:gsub("/+$", "")
    return p
  end
  local d = norm(doc_dir)
  local r = norm(root)
  if d == r then
    return ""
  end
  if d:sub(1, #r + 1) == r .. "/" then
    local rel = d:sub(#r + 2)
    local _, depth = rel:gsub("/", "")
    return ("../"):rep(depth + 1)
  end
  return ""
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
    elseif block.t == "CodeBlock" then
      -- Kode-blokea (.tree div-en barruan erabiltzen da Forest-eko komak
      -- babesteko): lerroak hitzez hitz hartu.
      for line in block.text:gmatch("[^\r\n]+") do
        local t = line:match("^%s*(.-)%s*$")
        if t ~= "" then table.insert(out, t) end
      end
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

-- Glossa div-a -> ExPex blokea. Lerro bakoitzak // amaiera behar du
-- (ExPex-ek argumentu iheskorra hartzen du bestela).
local function gloss_latex(lines)
  local parts = {}
  if lines[1] and lines[1] ~= "" then
    table.insert(parts, "\\gla " .. lines[1] .. " //")
  end
  if lines[2] and lines[2] ~= "" then
    table.insert(parts, "\\glb " .. lines[2] .. " //")
  end
  if lines[3] and lines[3] ~= "" then
    table.insert(parts, "\\glft " .. lines[3] .. " //")
  end
  return "\\begingl\n" .. table.concat(parts, "\n") .. "\n\\endgl"
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
    if block.t == "Div" and block.classes:includes("gloss") then
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
  -- Zuhaitza -> Forest.
  if el.classes:includes("tree") then
    local lines = div_lines(el)
    return pandoc.RawBlock("latex",
      "\\begin{forest}\n" .. table.concat(lines, "\n") .. "\n\\end{forest}")
  end

  -- Adibidea -> ExPex (zenbakitze globala).
  if el.identifier:match("^exm%-") then
    return pandoc.RawBlock("latex", example_latex(el))
  end

  -- Glossa (adibide baten barnean egon edo ez).
  if el.classes:includes("gloss") then
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

  -- HTML: zuhaitza SVG gisa (bide erlatiboa orrialdearen sakonerara egokitua).
  if el.classes:includes("tree") then
    local id = el.identifier or ""
    local src = asset_prefix() .. "assets/arbolak/" .. id .. ".svg"
    local alt = "Zuhaitz sintaktikoa: " .. id
    local img = pandoc.Image({pandoc.Str(alt)}, src, alt)
    return pandoc.Para({img})
  end

  -- HTML: glossa taula gisa (hitz-mailako lerrokatzea).
  -- Jatorrizko lerroa eta glossa hitzez hitz lotzen dira; itzulpen askea
  -- zutabe osoan zabaltzen da.
  if el.classes:includes("gloss") then
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
