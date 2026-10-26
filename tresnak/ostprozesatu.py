#!/usr/bin/env python3
"""HTML ostprozesatzailea: adibideen etiketak berridatzi.

Quarto-k `<strong>Adibidea 4.1</strong>` sortzen du. Hizkuntzalaritzako
konbentzioaren arabera `(4.1)` nahi dugu, ezkerreko marjinan zintzilik.

Erabilera:
    python tresnak/ostprozesatu.py            # _site/**/*.html
    python tresnak/ostprozesatu.py --check    # egiaztatu soilik
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SITE = ROOT / "_site"

# <strong>Adibidea 4.1</strong>  ->  <strong>(4.1)</strong>
PATTERN = re.compile(r"<strong>(Adibidea|Ariketa)\s+(\d+(?:\.\d+)*)</strong>")
REPLACEMENT = r"<strong>(\2)</strong>"


def process_file(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    new = PATTERN.sub(REPLACEMENT, text)
    if new != text:
        path.write_text(new, encoding="utf-8", newline="\n")
        return True
    return False


def main():
    check = "--check" in sys.argv
    if not SITE.exists():
        print(f"ERROREA: ez da aurkitu {SITE}")
        return 1

    changed = 0
    total = 0
    for html in SITE.rglob("*.html"):
        total += 1
        text = html.read_text(encoding="utf-8")
        new = PATTERN.sub(REPLACEMENT, text)
        if check:
            if new != text:
                print(f"ZAHARKITUTA: {html.relative_to(ROOT)}")
                changed += 1
        else:
            if new != text:
                html.write_text(new, encoding="utf-8", newline="\n")
                changed += 1

    print(f"Prozesatutako HTML: {total}; aldatutakoak: {changed}")
    if check and changed:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
