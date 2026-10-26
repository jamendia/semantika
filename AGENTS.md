# AGENTS.md — *Esanahia eta egitura*

Liburu honetan lanean hasteko agenteentzako fitxategia. Irakurri oso-osorik
kapitulu bat idazten hasi aurretik.

---

## 1. Proiektua

| | |
|---|---|
| Izenburua | *Esanahia eta egitura* |
| Azpititulua | *interpretazioaren zientzia* |
| Hizkuntza | Euskara batua (Euskaltzaindiaren arauak) |
| Egilea | Jamendia |
| Lizentzia | CC BY 4.0 |
| Biltegia | `github.com/jamendia/semantika` |
| Webgunea | `https://jamendia.github.io/semantika/` |
| Tresna | Quarto 1.10+ (book proiektua) |

Liburua ez da itzulpena. Egilearen euskarazko testu bat da, eta Roussarie
(2017, CC BY 4.0) eta Coppock & Champollion (baimendua) iturri gisa
erabiltzen dira. Xehetasunak: `CREDITS.md`.

---

## 2. Arau ukaezinak

1. **Ez igo inoiz `textbook-sources/` karpeta biltegira.** Hirugarrenen PDFak
   eta jatorrizko `.docx` fitxategiak daude bertan. `.gitignore`-k babestuta
   dago; ez kendu araua.
2. **Ez sartu ebazpenik biltegi publikoan.** Ariketen erantzunak beste
   biltegi pribatu batean bizi dira (`semantika-erantzunak`). Hemen ariketen
   enuntziatuak soilik.
3. **Terminologia ez da asmatzen.** Iturri arauemailea
   `terminologia/hiztegia.csv` da, egilearen eskuizkribuan oinarritua. Termino
   berri bat behar baduzu: gehitu CSVra `egoera=berria` markarekin eta erabili
   modu koherentean. Ez aldatu lehendik onartutako termino bat inolako
   kapitulutan, egileari galdetu gabe.
4. **Ez utzi markatzailerik argitaratutako testuan**: `TODO`, `XXXX`, `XREF`,
   `[[TERM:...]]`. `tresnak/terminoak-egiaztatu.py` hori egiaztatzen du eta
   CIk huts egiten du aurkitzen badu.
5. **Adibideak euskaraz lehenetsi.** Kanpoko hizkuntzetako datuak erabiltzen
   badira, euskarazko itzulpena eman.

---

## 3. Egitura

```
index.qmd                  Azala
hitzaurrea.qmd             Hitzaurrea
nola-irakurri.qmd          Nola irakurri liburua + edukiaren egitura osoa
kapituluak/                Kapituluak (izen garbiak, zenbakirik gabe)
  konposizioa.qmd          ← pilotua
eranskinak/
  a-terminologia.qmd       SORTUA: ez editatu eskuz
  b-ikurrak.qmd            Notazio-taula
  c-aipamena.qmd           Nola aitatu
terminologia/hiztegia.csv  Terminologiaren iturri bakarra
tex/
  aurrea.tex               PDFaren aurrea (expex, forest, unicode mapa)
  forest-ezarpenak.tex     Zuhaitzen ezarpenak (iturri bakarra: PDF + SVG)
tresnak/
  hiztegia.py              Hiztegia → eranskina sortzen du
  terminoak-egiaztatu.py   Kalitate-egiaztapena
  linguistika.lua          Pandoc iragazkia: zuhaitzak eta glossak
  arbolak.py               Forest → SVG (assets/arbolak/)
  ostprozesatu.py          HTML adibideen zenbakitze globala + --check
estilo/basque.scss         Estiloa
```

Kapituluen hurrenkera `_quarto.yml` fitxategian definitzen da, ez fitxategi-
izenetan. Karpeta-izenak egonkorrak dira: kapitulu bat mugitzeak ez du estekarik
apurtu behar.

### Kapitulu baten egitura estandarra

```markdown
---
title: "Kapituluaren izenburua"
---

## Sarrera

... (sarrera motza: zer arazo planteatzen den)

## ... garapena ...

## Laburpena

## Ariketak          ← beti azken-aurrekoa

## Irakurketa gehiago ← beti azkena
```

**Maila-kontua:** kapituluaren izenburua YAML buruan doa, eta atalak `##`
mailan hasten dira (`#` ez), azpiatalak `###`. Hori ezinbestekoa da adibideen
zenbakitzea kapitulu bakoitzeko berrabiarazteko: `##` erabiliz gero, *Adibidea
3.1*, *3.2*, *3.3*… agertuko dira; `#` erabiliz gero, aldiz, *atal* zenbakiak
hartuko ditu (*Adibidea 5.1*), eta hori okerra da.

Txantiloia: `kapituluak/_txantiloia.qmd` (ez da errendatzen).

Ariketen IDak: `::: {#exr-<kapitulua>-<zenbakia>}`. Adibidez `#exr-konp-1`.
Ebazpenak beste biltegian ID berarekin gordetzen dira.

### Adibideen zenbakitzea eta glossak (garrantzitsua)

**Adibideak (`#exm-`) liburu osoan zenbatzen dira: `(1), (2), (3)…`, ez
kapituluko `(4.1)`.** Ariketak (`#exr-`), aldiz, kapituluko zenbakitzea
gorde behar dute: `(4.1)`. Bi formatuek berdin errendatu behar dute:

- **PDF:** crossref-ek sortutako `example` ingurunea `tex/aurrea.tex`-ek
  birdefinitzen du `\AtBeginDocument`-ean, kontagailu global batekin
  (`adibkont`). Ez aldatu hori arazorik gabe.
- **HTML:** Quarto-k `Adibidea 4.1` etiketa sortzen du, eta
  `python tresnak/ostprozesatu.py`-k `(n)` global bihurtzen du
  `_quarto.yml`-ko kapitulu ordena jarraituz. `--check` modua CI-rako:
  idempotentea dela eta `(1)…(n)` sekuentzia osoa dagoela egiaztatzen du.

**Glossa interlineala** hizkuntza arrotzetako adibideentzat soilik;
euskarazko adibideak ez dira inoiz glossatzen. Glossa `#exm-` div baten
**barnean** kapsulatzen da (zenbaki bakarra adibide bakoitzeko):

```markdown
::: {#exm-eskopa-en}
::: {.gloss}
Every student read two books
every student read.PST two book.PL
Ikasle guztiek bi liburu irakurri dituzte.
:::
:::
```

Hiru lerro: jatorrizko perpausa, glossa morfosintaktikoa, itzulpen askea.
PDFan ExPex-en `\gla/\glb/\glft` bihurtzen du `tresnak/linguistika.lua`-k;
HTMLan `div.gloss` sortzen du.

**Zuhaitzak:** `::: {.tree #id}` div-ak, parentesi etiketatuekin
(`[P [IS Ane-k] [AS ...]]`). PDFan Forest; HTMLan SVG
(`python tresnak/arbolak.py`-k sortuak, biltegian gordeta). Ezarpenak
`tex/forest-ezarpenak.tex`-en: iturri bakarra PDF eta SVGrentzat.

---

## 4. Terminologia

Iturri bakarra: `terminologia/hiztegia.csv` (`;` bidez bereizia).

Zutabeak: `eu;en;definizioa;oharrak;egoera`

- `egoera`: `onartua` (egileak berretsia), `berria` (proposamena), `berrikusteko`.
- Aldatu ondoren: `python tresnak/hiztegia.py` → `eranskinak/a-terminologia.qmd`
  birsortzen da.

### Nahitaez errespetatu beharreko bereizketa

| Kontzeptua | Termino arauemailea | **Ez** erabili |
|---|---|---|
| sentence | **perpausa** | ~~esaldia~~ |
| utterance | **esaldia** | ~~perpausean esana~~ |
| meaning | **esanahia** | ~~esangura~~ |
| semantic value | **balio semantikoa** | ~~balore semantikoa~~ |
| referent | **erreferentziagaia** | ~~erreferentea~~ |
| model | **eredua** | ~~modeloa~~ |

Hau da proiektuko akatsik ohikoena: `esaldia` eta `perpausa` trukatzea.
Argi gorde: **perpausa = sentence; esaldia = utterance.**

### Sintaxi-etiketak

| Etiketa | Esanahia |
|---|---|
| `P` | perpausa |
| `IS` | izen sintagma |
| `AS` | aditz sintagma |
| `DetS` | determinatzaile sintagma |

Ez erabili ingelesezko `S`, `NP`, `VP`, `DP`.

---

## 5. Notazioa

| Kontzeptua | Idazkera | Oharrak |
|---|---|---|
| Denotazioa | `⟦α⟧^ℰ` | Kako zuriak (U+27E6/27E7), ez `[[ ]]`: Typst-ek matrize gisa interpretatzen du |
| Tipoak | `⟨e, t⟩` | Ez `<e,t>` testu lauan |
| Lambda | `λx[ ... ]` | |
| Eredua | `ℰ` | |
| Itzulpen lexikoa | `etorri'` | Apostrofo bakuna |
| Aplikazioa | `⟦ikusi'⟧^ℰ(⟦amaia⟧^ℰ)` | |

Matematika `$...$` eta `$$...$$` artean, karaktere unicode literalekin
(`⟦⟧`, `⟨⟩`, `λ`, `ℰ`). Ez erabili `\begin{array}` baino konstruktu
exotikorik: HTMLrako MathJax eta PDFrako LaTeX (lualatex) bietara heldu
behar du. PDFaren aldean karaktere horiek `tex/aurrea.tex`-eko
`\newunicodechar` mapak bihurtzen ditu makrotara; karaktere matematiko berri
bat erabili behar bada, gehitu mapa horri.

Zuhaitzak: parentesi etiketatuak `::: {.tree #id}` div batean
(`[P [IS Ane-k] [AS [IS Amaia] [A ikusi]]]`), eta gehienez zuhaitz bat edo bi
kapitulu bakoitzean.

---

## 6. Estiloa

- Erregistro akademikoa, baina irakurgarria. Bigarren pertsona singularra
  irakurleari zuzentzeko (`ikus dezakezu`), inpertsonala azalpenean.
- Perpaus laburrak. Paragrafo bat, ideia bat.
- Ez erabili gaztelaniazko kalkoak: *en base a* → `oinarrituta`;
  *a nivel de* → `mailan`; *el mismo* → `bera`.
- Marratxoa: `egi-balioa`, `tipo-teoria`? Ez: **`tipo semantikoa`** (bi hitz),
  `egi-balioa` (marratxoduna), `esanahi-hartzailea` (marratxoduna).
- Zenbaki ordinalak: `1.`, `2.` eta ez `1.a`.
- Aipamenak: `(Roussarie 2017: 42)`; bibliografia osoa kapituluaren amaieran.

---

## 7. Eraikitzea eta egiaztatzea

```bash
python tresnak/hiztegia.py          # hiztegia birsortu
python tresnak/terminoak-egiaztatu.py  # QA: markatzaileak, termino okerrak
python tresnak/arbolak.py           # zuhaitz berriak SVG bihurtu (--check: egiaztatu)
quarto render                       # HTML + PDF (_site/)
python tresnak/ostprozesatu.py      # HTML: adibideen zenbakitze globala
python tresnak/ostprozesatu.py --check  # CI: idempotentzia + (1)..(n) sekuentzia
quarto preview                      # tokiko aurrebista
```

**Oharra:** `quarto render --to html` bakarrik exekutatuz gero, Quarto-k
`_site` garbitzen du eta PDFa ezabatzen du. Azken egoeran beti errendatu
bi formatuak elkarrekin (`quarto render`, formaturik gabe).

CIk (`.github/workflows/`) guztiak exekutatzen ditu push bakoitzean.
`quarto render` huts egiten badu, ez egin commit.

---

## 8. Ezagutzekoak diren akatsak (Quarto `eu` lokalizazioa)

Quarto 1.10.18ren euskarazko itzulpenak akats hauek ditu. Ez ditugu
zuzentzen, baina kontuan hartu:

| Gakoa | Balioa | Zuzena litzateke |
|---|---|---|
| `callout-tip-title` | `Ahoulkua` | `Aholkua` |
| `environment-proof-title` | `Proba` | `Froga` |
| `environment-solution-title` | `Emaitza` | `Ebazpidea` |

Gainera, erreferentziak aurrizki gisa agertzen dira: `Atala 1.1`,
`Kapitulua 3`. Euskaran ohikoagoa litzateke `1.1. atala`, `3. kapitulua`,
baina Quarto-k ez du atzizkirik onartzen. **Ondorio praktikoa:** ez erabili
`@sec-` edo `@ch-` erreferentziak testuan; idatzi `aurreko atalean`,
`3. kapituluan` eta antzekoak eskuz. `@exm-` erreferentziak onargarriak dira
(`Adibidea 1.1`), baina hobe da horiek gutxi erabiltzea.

**Zenbakitzea:** kapitulu-zenbakia `_quarto.yml`-ko ordenaren araberakoa da.
Orain hitzaurrea eta "Nola irakurri" atalak 2. eta 3. kapitulu gisa agertzen
dira; edo onargarria da, edo `{.unnumbered}` bidez konpondu beharko litzateke
geroago (Quarto 1.10-en ez du garbi funtzionatzen liburu-proiektuetan).
Kapitulu berriak gehitzean, zenbakiak automatikoki berrantolatzen dira.

### PDFaren mugarri teknikoak (ez aldatu arrazoirik gabe)

- **ExPex + unicode-math gatazka:** Quarto-txantiloiak `unicode-math`
  kargatzen du lualatex-entzat, eta pakete horrek `\AtBeginDocument`-ean
  beraplikatzen du bere ikur-taula. Taulan U+2AA5 ikurraren izena `\gla` da,
  eta ExPex-en `\gla` (glossaren lehen lerroa) suntsitzen du: `\endgl`
  huts egiten du ("Too many }'s"). Konponketa `tex/aurrea.tex`-en dago:
  `\gla/\glb/\glc/\glft` kopiatu eta `\AtBeginDocument`-ean bueltatu.
  Ez kendu; beste konponbide bakarra unicode-math ez erabiltzea da, eta
  Quarto-txantiloiak ez du hori baimentzen.
- **Crossref-en custom AST:** quarto-pre fasean crossref-ek `#exm-`/`#exr-`
  div-ak nodo pertsonal bihurtzen ditu, erabiltzaile-iragazkientzat
  ikusegin (identifikatzailerik gabe iristen zaizkio `Div` maneiatzaileari).
  Gainera, `require("quarto")` ez dabil erabiltzaile-iragazkietan. Ondorioz:
  adibideak ezin dira iragazkiaren bidez `\ex/\pex` bihurtu PDFan; horregatik
  `example` ingurunea birdefinitzen da `tex/aurrea.tex`-en. `.tree` eta
  `.gloss` div-ak, aldiz, iragazkiraino iristen dira eta hark kudeatzen ditu.
- **`~` lausoa:** crossref-ek `~` jartzen du adibidearen lehen paragrafo
  gisa; `tex/aurrea.tex`-eko ingurune berriak neutralizatzen du, zenbakia
  lehenengo eduki-lerroan ager dadin.

---

## 9. Kalitate-ateak

Kapitulu bat "egina" dela esateko:

- [ ] `quarto render` akatsik gabe (bi formatuak: HTML + PDF).
- [ ] `python tresnak/terminoak-egiaztatu.py` akatsik gabe.
- [ ] `python tresnak/ostprozesatu.py --check` akatsik gabe.
- [ ] Termino berri guztiak `hiztegia.csv`-n erregistratuta.
- [ ] Adibide gakoek `#exm-` IDa dute, eta testuan erreferentzia egiten zaie.
- [ ] Ariketek `#exr-` IDa dute.
- [ ] Sarrera, Laburpena, Ariketak eta Irakurketa gehiago atalak daude.
- [ ] Iturbururen bat erabili bada, kapituluaren amaieran aitortu.
