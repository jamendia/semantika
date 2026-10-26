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
tresnak/hiztegia.py        Hiztegia → eranskina sortzen du
tresnak/terminoak-egiaztatu.py  Kalitate-egiaztapena
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

Matematika `$...$` eta `$$...$$` artean. Ez erabili `\begin{array}` baino
konstruktu exotikorik: HTMLrako MathJax eta PDFrako Typst bietara heldu behar du.

Zuhaitzak: parentesi etiketatuak lehentsi
(`[P [IS Ane-k] [AS [IS Amaia] [A ikusi]]]`), eta gehienez zuhaitz bat edo bi
marraztu `array` bidez kapitulu bakoitzean.

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
quarto render                       # HTML + PDF (_site/)
quarto preview                      # tokiko aurrebista
```

CIk (` .github/workflows/`) hirurak exekutatzen ditu push bakoitzean.
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

---

## 9. Kalitate-ateak

Kapitulu bat "egina" dela esateko:

- [ ] `quarto render` akatsik gabe.
- [ ] `python tresnak/terminoak-egiaztatu.py` akatsik gabe.
- [ ] Termino berri guztiak `hiztegia.csv`-n erregistratuta.
- [ ] Adibide gakoek `#exm-` IDa dute, eta testuan erreferentzia egiten zaie.
- [ ] Ariketek `#exr-` IDa dute.
- [ ] Sarrera, Laburpena, Ariketak eta Irakurketa gehiago atalak daude.
- [ ] Iturbururen bat erabili bada, kapituluaren amaieran aitortu.
