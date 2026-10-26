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


def process_text(text: str, counter: list[int]) -> tuple[str, list[int]]:
    """Etiketak berridatzi. `counter[0]` da hurrengo zenbaki globala;
    itzulitako bigarren balioa kapitulu honetan esleitutako mapa da
    (kapituluko N.M -> globala), erreferentzientzat."""
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

    return LABEL_RE.sub(repl, text), assigned


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
