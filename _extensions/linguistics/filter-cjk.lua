--[==[
  filter-cjk.lua -- Unicode text that Latin Modern cannot typeset

  Two things a linguistics paper needs that Quarto's PDF chain silently
  mangles:

  1. CJK text. Latin Modern has no Chinese/Japanese/Korean glyphs and LaTeX
     simply drops the characters.  This filter declares a fontspec family for
     each script present (choosing the first font that exists on the system)
     and wraps every run of CJK characters in it.  It works with both PDF
     engines because it uses fontspec only, not xeCJK.

  2. Greek letters and logical symbols used in semantic derivations
     (λ, ∀, ∃, ι, →, ∧, ⟦, ⟧).  These are routed through math mode, where
     every TeX installation has them.

  Override the CJK font candidates in the document header:

      ling-cjk-font: "Malgun Gothic"
      # or a list, tried in order:
      ling-cjk-font: ["Malgun Gothic", "Noto Serif CJK JP"]
]==]

local HANGUL_FONTS = {
  "Malgun Gothic", "Apple SD Gothic Neo", "Noto Sans CJK KR",
  "Noto Serif CJK KR", "Source Han Sans KR", "NanumGothic",
}
local KANA_FONTS = {
  "Yu Gothic", "Meiryo", "Hiragino Mincho ProN", "Noto Sans CJK JP",
  "IPAexMincho", "Noto Serif CJK JP",
}
local HAN_FONTS = {
  "Microsoft YaHei", "SimSun", "PingFang SC", "Noto Sans CJK SC",
  "Source Han Serif SC", "Noto Serif CJK SC",
}

-- codepoint -> LaTeX math
local SYMBOLS = {
  [0x03B1] = "\\alpha", [0x03B2] = "\\beta", [0x03B3] = "\\gamma",
  [0x03B4] = "\\delta", [0x03B5] = "\\epsilon", [0x03B6] = "\\zeta",
  [0x03B7] = "\\eta", [0x03B8] = "\\theta", [0x03B9] = "\\iota",
  [0x03BA] = "\\kappa", [0x03BB] = "\\lambda", [0x03BC] = "\\mu",
  [0x03BD] = "\\nu", [0x03BE] = "\\xi", [0x03C0] = "\\pi",
  [0x03C1] = "\\rho", [0x03C3] = "\\sigma", [0x03C4] = "\\tau",
  [0x03C6] = "\\phi", [0x03C7] = "\\chi", [0x03C8] = "\\psi",
  [0x03C9] = "\\omega", [0x0393] = "\\Gamma", [0x0394] = "\\Delta",
  [0x0398] = "\\Theta", [0x039B] = "\\Lambda", [0x03A0] = "\\Pi",
  [0x03A3] = "\\Sigma", [0x03A6] = "\\Phi", [0x03A8] = "\\Psi",
  [0x03A9] = "\\Omega",
  [0x2200] = "\\forall", [0x2203] = "\\exists", [0x2204] = "\\nexists",
  [0x2227] = "\\wedge", [0x2228] = "\\vee", [0x00AC] = "\\neg",
  [0x2192] = "\\to", [0x21D2] = "\\Rightarrow", [0x21D4] = "\\Leftrightarrow",
  [0x2286] = "\\subseteq", [0x2282] = "\\subset", [0x2287] = "\\supseteq",
  [0x2208] = "\\in", [0x2209] = "\\notin", [0x2205] = "\\emptyset",
  [0x2260] = "\\neq", [0x2264] = "\\leq", [0x2265] = "\\geq",
  [0x2295] = "\\oplus", [0x2297] = "\\otimes", [0x2207] = "\\nabla",
  [0x2211] = "\\sum", [0x2202] = "\\partial", [0x221E] = "\\infty",
  [0x27E6] = "[\\![", [0x27E7] = "]\\!]",
}

local function is_cjk(cp)
  return (cp >= 0x2E80 and cp <= 0x2FFF)
      or (cp >= 0x3000 and cp <= 0x30FF)
      or (cp >= 0x3130 and cp <= 0x318F)
      or (cp >= 0x3400 and cp <= 0x4DBF)
      or (cp >= 0x4E00 and cp <= 0x9FFF)
      or (cp >= 0xA960 and cp <= 0xA97F)
      or (cp >= 0xAC00 and cp <= 0xD7AF)
      or (cp >= 0xF900 and cp <= 0xFAFF)
      or (cp >= 0xFE30 and cp <= 0xFE4F)
      or (cp >= 0xFF00 and cp <= 0xFFEF)
      or (cp >= 0x20000 and cp <= 0x2FA1F)
end

local function is_hangul(cp)
  return (cp >= 0xAC00 and cp <= 0xD7A3) or (cp >= 0x3130 and cp <= 0x318F)
      or (cp >= 0x1100 and cp <= 0x11FF)
end

local function is_kana(cp)
  return cp >= 0x3040 and cp <= 0x30FF
end

local function is_han(cp)
  return (cp >= 0x3400 and cp <= 0x4DBF)
      or (cp >= 0x4E00 and cp <= 0x9FFF)
      or (cp >= 0xF900 and cp <= 0xFAFF)
      or (cp >= 0x20000 and cp <= 0x2FA1F)
end

local state = {
  cjk = false, hangul = false, kana = false, han = false,
  han_family = "lingcjkhan",
}

local function scan(text)
  pcall(function()
    for _, cp in utf8.codes(text) do
      if is_cjk(cp) then
        state.cjk = true
        if is_hangul(cp) then state.hangul = true end
        if is_kana(cp) then state.kana = true end
        if cp >= 0x3400 and cp <= 0x9FFF then state.han = true end
      end
    end
  end)
end

local function configured(meta, key)
  local v = meta[key]
  if not v then return nil end
  local out = {}
  if type(v) == "table" and v.t == "MetaList" then
    for _, item in ipairs(v) do table.insert(out, pandoc.utils.stringify(item)) end
  else
    table.insert(out, pandoc.utils.stringify(v))
  end
  return #out > 0 and out or nil
end

local function declare(name, fonts, i)
  i = i or 1
  if i > #fonts then
    io.stderr:write("linguistics: no CJK font found for " .. name
      .. "; set ling-cjk-font in the document header\n")
    return string.format("\\providecommand{\\%s}{}", name)
  end
  local f = fonts[i]:gsub("[{}%%#]", "")
  return string.format("\\IfFontExistsTF{%s}{\\newfontfamily\\%s{%s}}{%s}",
    f, name, f, declare(name, fonts, i + 1))
end

-- ---------------------------------------------------------------- inlines
local function wrap_inlines(inlines)
  local out = pandoc.Inlines({})
  for _, x in ipairs(inlines) do
    if x.t == "Str" then
      local run, cur = {}, nil

      local function flush()
        if #run == 0 then return end
        local text = table.concat(run)
        if cur == nil then
          out:insert(pandoc.Str(text))
        elseif cur == "math" then
          out:insert(pandoc.RawInline("latex", "$" .. text .. "$"))
        else
          out:insert(pandoc.RawInline("latex", "{\\" .. cur .. " " .. text .. "}"))
        end
        run = {}
      end

      for _, cp in utf8.codes(x.text) do
        local mode, text
        local sym = SYMBOLS[cp]
        if sym then
          mode, text = "math", sym
        elseif is_cjk(cp) then
          mode, text = state.han_family, utf8.char(cp)
          if is_kana(cp) and state.kana then
            mode = "lingcjkjp"
          elseif is_hangul(cp) and state.hangul then
            mode = "lingcjk"
          end
        else
          mode, text = nil, utf8.char(cp)
        end
        if mode ~= cur then
          flush()
          cur = mode
        end
        table.insert(run, text)
      end
      flush()
    else
      out:insert(x)
    end
  end
  return out
end

function Pandoc(doc)
  if not (quarto.doc.isFormat("latex") or quarto.doc.isFormat("pdf")) then
    return doc
  end

  state = {
    cjk = false, hangul = false, kana = false, han = false,
    han_family = "lingcjkhan",
  }
  scan(pandoc.utils.stringify(doc.blocks))

  -- Han characters are shared by Chinese, Japanese and Korean, and a font
  -- for one of those scripts does not necessarily have them (Malgun Gothic
  -- has no Han).  Route them to the script that is actually present.
  if state.kana then
    state.han_family = "lingcjkjp"
  elseif state.hangul then
    state.han_family = "lingcjk"
  end

  if state.cjk then
    local header = {}
    if state.hangul then
      table.insert(header, declare("lingcjk",
        configured(doc.meta, "ling-cjk-font") or HANGUL_FONTS))
    end
    if state.kana then
      table.insert(header, declare("lingcjkjp",
        configured(doc.meta, "ling-cjk-font-jp") or KANA_FONTS))
    end
    if state.han_family == "lingcjkhan" then
      table.insert(header, declare("lingcjkhan",
        configured(doc.meta, "ling-cjk-font-han") or HAN_FONTS))
    end
    if #header > 0 then
      pcall(function()
        quarto.doc.include_text("in-header", table.concat(header, "\n"))
      end)
    end
  end

  -- A tree div is re-read as plain bracket text by filter-tree, so anything
  -- this filter rewrites inside one is lost (an inline turned into raw LaTeX
  -- stringifies to nothing, and symbols such as ∅ simply vanish).  Park those
  -- divs, transform the rest, then put them back untouched.
  local parked, n = {}, 0
  doc = doc:walk({
    Div = function(el)
      if not el.classes:includes("tree") then return nil end
      n = n + 1
      local key = "LINGTREE" .. n .. "X"
      parked[key] = el
      return pandoc.RawBlock("html", key)
    end,
  })

  doc = doc:walk({ Inlines = function(inlines) return wrap_inlines(inlines) end })

  doc = doc:walk({
    RawBlock = function(el)
      if el.format == "html" then
        local el2 = parked[el.text]
        if el2 then return el2 end
      end
      return nil
    end,
  })
  return doc
end
