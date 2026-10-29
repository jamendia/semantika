#!/usr/bin/env python3
"""HTML ostprozesatzailea: adibideen zenbakitze globala.

Quarto-k adibideak kapituluko zenbakitzearekin errendatzen ditu
(`<strong>Adibidea 4.1</strong>`). Hizkuntzalaritzako konbentzioaren
arabera, adibideak liburu osoan zenbakitzen dira: `(1), (2), (3)...`,
eta ezkerreko marjinan zintzilik daude. Ariketek, aldiz, kapituluko
zenbakitzea gordetzen dute: `(4.1)`.

Kapituluen hurrenkera `_quarto.yml`-etik irakurtzen da, eta kontagailu
globala kapitulu ordenan igarotzen da. Adibide baten bigarren aipamen
bat (erreferentzia) lehen esleitutako zenbakia jasotzen du.

Gainera, crossref-ek sortutako adibide-divak berrantolatzen dira:
etiketa `<span class="exnum">` bihurtzen da eta edukia
`<div class="example-body">`-n sartzen, zenbakia eta edukia lerro
berean oinarri-linean jartzeko (`estilo/basque.css` grid diseinua).

Erabilera:
    python tresnak/ostprozesatu.py            # _site/**/*.html berridatzi
    python tresnak/ostprozesatu.py --check    # egiaztatu soilik (CI)
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SITE = ROOT / "_site"
YML = ROOT / "_quarto.yml"

# <strong>Adibidea 4.1</strong> / <strong>Ariketa 4.2</strong>
LABEL_RE = re.compile(r"<strong>(Adibidea|Ariketa)\s+(\d+(?:\.\d+)*)</strong>")

# Ostprozesatu ondorengo etiketa globala: <strong>(7)</strong>
GLOBAL_RE = re.compile(r'<strong>\((\d+)\)</strong>')

# Crossref-ek sortutako adibide-divaren etiketa (berrantolatu beharrekoa).
# Bi forma:
#   <p><span class="theorem-title"><strong>(7)</strong></span> &nbsp;</p>
#   <p><span class="theorem-title"><strong>(5)</strong></span> <em>Adibidea...</em></p>
#   <p><span class="theorem-title"><strong>(10)</strong></span> <img ...></p>
# Pandoc-ek etiketa eta adibidearen lehen paragrafoa elkartzen ditu; `rest`
# taldeak etiketaren atzean dagoen guztia hartzen du (`&nbsp;` hutsa,
# esaldia edo irudia). Ariketa eta definizioen etiketek, aldiz, `exr-`/
# `def-` id-a dute eta EXAMPLE_DIV_RE-k ez die bat egiten.
LABEL_P_RE = re.compile(
    r'(?P<lead>\s*)<p><span class="theorem-title">'
    r'(?P<num><strong>\(\d+\)</strong>)</span>'
    r'(?P<rest>.*?)</p>', re.DOTALL)

# Crossref-ek sortutako adibide-divaren irekitzailea.
EXAMPLE_DIV_RE = re.compile(
    r'<div id="exm-[^"]+"[^>]*class="[^"]*\bexample\b[^"]*"[^>]*>')

# Div tokenak (irekitzailea / itxiera) zuhaitz-sakoneraren bila.
DIV_TOKEN_RE = re.compile(r'<div\b[^>]*>|</div>')


def chapter_files() -> list[Path]:
    """_quarto.yml-ko kapitulu ordena (qmd bideak, agertzen diren ordenan)."""
    files: list[Path] = []
    for line in YML.read_text(encoding="utf-8").splitlines():
        m = re.match(r"^\s*-\s+(\S+\.qmd)\s*$", line)
        if m:
            files.append(ROOT / m.group(1))
    return files


def html_path(qmd: Path) -> Path:
    rel = qmd.relative_to(ROOT)
    return SITE / rel.with_suffix(".html")


def find_div_close(text: str, start: int) -> int | None:
    """`start` puntutik aurrera (div irekitzailearen ondotik, sakonera=1)
    sakonera-kontuarekin `</div>` parekatua bilatu. Itzulerak: itxieraren
    hasiera-posizioa, edo None ez bada aurkitzen."""
    depth = 1
    pos = start
    while pos < len(text):
        m = DIV_TOKEN_RE.search(text, pos)
        if m is None:
            return None
        if m.group(0) == "</div>":
            depth -= 1
            if depth == 0:
                return m.start()
        else:
            depth += 1
        pos = m.end()
    return None


def restructure(text: str) -> str:
    """Crossref-ek sortutako adibide-divak berrantolatu.

    Aurretik:
        <div id="exm-x" class="theorem example">
        <p><span class="theorem-title"><strong>(7)</strong></span> &nbsp;</p>
        <p>edukia</p>
        </div>

    Ondoren:
        <div id="exm-x" class="theorem example">
        <span class="exnum"><strong>(7)</strong></span>
        <div class="example-body">
        <p>edukia</p>
        </div>
        </div>

    Zenbakia eta edukia lerro berean jartzeko (`estilo/basque.css`-eko grid
    diseinuak erabiltzen du). Idempotentea: berrantolatu ondoren etiketa
    ez dago jada `<p><span class="theorem-title">...` formatuan."""
    out: list[str] = []
    pos = 0
    for m in EXAMPLE_DIV_RE.finditer(text):
        if m.start() < pos:
            continue
        open_end = m.end()
        close_start = find_div_close(text, open_end)
        if close_start is None:
            continue
        content = text[open_end:close_start]
        lm = LABEL_P_RE.match(content)
        if lm is None:
            continue
        num = lm.group('num')
        rest = lm.group('rest')
        # Etiketaren atzean dagoena gorputzera eraman (esaldia, irudia...);
        # hasierako/amaierako `&nbsp;` eta zuriuneak bakarrik botatzen dira,
        # barneko edukia ukitu gabe.
        inner = re.sub(r'^(?:\s|&nbsp;|\u00a0)+', '', rest)
        inner = re.sub(r'(?:\s|&nbsp;|\u00a0)+$', '', inner)
        body = f'<p>{inner}</p>' if inner else ''
        out.append(text[pos:m.start()])
        out.append(text[m.start():open_end])
        out.append('\n<span class="exnum">')
        out.append(num)
        out.append('</span>\n<div class="example-body">')
        if body:
            out.append('\n' + body)
        out.append(content[lm.end():])
        out.append('</div>')
        pos = close_start
    out.append(text[pos:])
    return "".join(out)


def process_text(text: str, counter: list[int]) -> tuple[str, list[int]]:
    """Etiketak berridatzi eta adibide-divak berrantolatu.
    `counter[0]` da hurrengo zenbaki globala; itzulitako bigarren balioa
    kapitulu honetan esleitutako mapa da (kapituluko N.M -> globala),
    erreferentzientzat."""
    assigned: dict[str, int] = {}

    def repl(m: re.Match) -> str:
        mota, nm = m.group(1), m.group(2)
        if mota == "Ariketa":
            # Ariketak kapituluko zenbakitzea gordetzen du: (4.1)
            return f"<strong>({nm})</strong>"
        if nm in assigned:
            # Erreferentzia: lehendik esleitutako zenbakia.
            return f"<strong>({assigned[nm]})</strong>"
        assigned[nm] = counter[0]
        counter[0] += 1
        return f"<strong>({assigned[nm]})</strong>"

    text = LABEL_RE.sub(repl, text)
    return restructure(text), assigned


def check_sequence(paths: list[Path]) -> list[str]:
    """Kapitulu ordenan <strong>(n)</strong> etiketak 1, 2, 3... jarraitzen
    dutela egiaztatu (adibideak; ariketen (N.M) etiketak baztertzen dira)."""
    errors: list[str] = []
    expected = 1
    for path in paths:
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        for m in GLOBAL_RE.finditer(text):
            n = int(m.group(1))
            if n != expected:
                errors.append(
                    f"{path.relative_to(ROOT)}: (n) esperotakoa ({expected}), "
                    f"aurkitutakoa ({n})")
                expected = n
            expected += 1
    return errors


def main() -> int:
    check = "--check" in sys.argv
    if not YML.exists():
        print(f"ERROREA: ez da aurkitu {YML}")
        return 1
    if not SITE.exists():
        print(f"ERROREA: ez da aurkitu {SITE}")
        return 1

    chapters = chapter_files()
    paths = [html_path(q) for q in chapters]
    missing = [p for p in paths if not p.exists()]
    if missing:
        print("ABISUA: HTMLrik ez dago hauekentzat:")
        for p in missing:
            print(f"  {p.relative_to(ROOT)}")

    counter = [1]
    changed = 0
    processed = 0
    for path in paths:
        if not path.exists():
            continue
        processed += 1
        text = path.read_text(encoding="utf-8")
        new, _ = process_text(text, counter)
        if check:
            if new != text:
                print(f"ZAHARKITUTA: {path.relative_to(ROOT)}")
                changed += 1
        else:
            if new != text:
                path.write_text(new, encoding="utf-8", newline="\n")
                changed += 1

    print(f"Prozesatutako HTML: {processed}; adibideak guztira: {counter[0] - 1}; "
          f"aldatutakoak: {changed}")

    if check and changed:
        return 1

    seq_errors = check_sequence(paths)
    for e in seq_errors:
        print(f"SEKUENTZIA-ERROREA: {e}")
    if seq_errors:
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
