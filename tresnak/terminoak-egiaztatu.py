#!/usr/bin/env python3
"""Kalitate-egiaztapena liburuko testuetarako.

Egiaztatzen du:
  1. Ez dagoela argitaratzeko markatzailerik (TODO, XXXX, XREF...).
  2. Ez dagoela termino debekaturik edo akats ezagunik.
  3. ID bikoizturik ez dagoela (exm-, exr-, def-...).
  4. Erreferentziak (@exm-x, @def-x...) existitzen diren IDetara doazela.
  5. Kapitulu bakoitzak derrigorrezko atalak dituela.

Erabilera:
    python tresnak/terminoak-egiaztatu.py
    python tresnak/terminoak-egiaztatu.py --zorroztu   # oharrak errore bihurtu

Irteera-kodea 0 bada, dena ondo dago.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Ez dira aztertzen: sortutako edo lan-materialak dituzten karpetak
# (kapituluak, eranskinak eta erroko .qmd-ak soilik begiratzen dira).
BAZTERTU_KARPETAK = {
    "_site", ".quarto", ".git", "textbook-sources", "tresnak",
    "_extensions", ".github", "estilo", "tex", "plana", "assets",
    "state", "quarto-txantiloi", "semantika-itzulpena",
    # Luzapenaren demo-proiektua: ez da liburuaren parte (ikusi .gitignore).
    "quarto-ling",
}
SORTUTAKO_FITXATEGIAK = {"eranskinak/a-terminologia.qmd"}

# 1. Argitaratu aurretik kendu beharreko markatzaileak
MARKATZAILEAK = [
    (re.compile(r"\bTODO\b"), "TODO markatzailea"),
    (re.compile(r"\bFIXME\b"), "FIXME markatzailea"),
    (re.compile(r"\bXXXX+\b"), "XXXX aipamen falta"),
    (re.compile(r"\bXREF\b"), "XREF erreferentzia falta"),
    (re.compile(r"\[\[TERM:"), "TERM markatzailea"),
    (re.compile(r"\?\?\?"), "??? zalantza-marka"),
]

# 2. Terminologia eta ortografia akats ezagunak (eskuizkributik heredatuak)
AKATS_OHIKOAK = [
    (r"(?<!\w)kooperazio\s+hatsarre", "kooperazio hatsarrea", "konposizionalitatearen hatsarrea"),
    (r"(?<!\w)modeloa(?!\w)", "modeloa", "eredua"),
    (r"(?<!\w)balore(?!\w)", "balore", "balio"),
    (r"(?<!\w)erreferentea(?!\w)", "erreferentea", "erreferentziagaia"),
    (r"(?<!\w)esangura(?!\w)", "esangura", "esanahia"),
    (r"(?<!\w)kuantifizaile\w*", "kuantifizaile", "kuantifikatzaile"),
    (r"(?<!\w)indibilual\w*", "indibilual", "indibidual"),
    (r"(?<!\w)konbentzioanal\w*", "konbentzioanal", "konbentzional"),
    (r"(?<!\w)esagebe\w*", "esagebe", "asegabe"),
    (r"(?<!\w)perpausen\s+esaldia", "perpausen esaldia", "esanahia / perpausa"),
    (r"(?<!\w)azpiindize(?!\w)", "azpiindize", "azpi-indize"),
]

# 3. Kapituluen derrigorrezko atalak
DERRIGORREZKO_ATALAK = ["# Ariketak", "# Irakurketa gehiago"]

ID_ERREGELA = re.compile(r"\{#((?:exm|exr|def|tbl|fig|eq|sec)-[\w.-]+)")
ERREF_ERREGELA = re.compile(r"@((?:exm|exr|def|tbl|fig|eq)-[\w.-]+)")


class Txostena:
    def __init__(self) -> None:
        self.erroreak: list[str] = []
        self.oharrak: list[str] = []

    def errorea(self, kokapena: str, mezua: str) -> None:
        self.erroreak.append(f"{kokapena}: {mezua}")

    def oharra(self, kokapena: str, mezua: str) -> None:
        self.oharrak.append(f"{kokapena}: {mezua}")


def fitxategiak():
    for bidea in sorted(ROOT.rglob("*.qmd")):
        erlatiboa = bidea.relative_to(ROOT)
        if any(zatia in BAZTERTU_KARPETAK for zatia in erlatiboa.parts):
            continue
        if erlatiboa.as_posix() in SORTUTAKO_FITXATEGIAK:
            continue
        yield bidea, erlatiboa


def main() -> int:
    txostena = Txostena()
    ids: dict[str, str] = {}
    erreferentziak: list[tuple[str, str, int]] = []

    for bidea, erlatiboa in fitxategiak():
        testua = bidea.read_text(encoding="utf-8")
        lerroak = testua.splitlines()
        kokapena = erlatiboa.as_posix()

        for zenbakia, lerroa in enumerate(lerroak, start=1):
            for erregela, izena in MARKATZAILEAK:
                if erregela.search(lerroa):
                    txostena.errorea(f"{kokapena}:{zenbakia}", f"{izena} aurkitu da")

            for patroia, okerra, zuzena in AKATS_OHIKOAK:
                if re.search(patroia, lerroa, flags=re.IGNORECASE):
                    txostena.errorea(
                        f"{kokapena}:{zenbakia}",
                        f"'{okerra}' -> '{zuzena}'",
                    )

            for ida in ID_ERREGELA.findall(lerroa):
                if ida in ids:
                    txostena.errorea(
                        f"{kokapena}:{zenbakia}",
                        f"ID bikoiztua: #{ida} (lehenago {ids[ida]})",
                    )
                else:
                    ids[ida] = f"{kokapena}:{zenbakia}"

            for erref in ERREF_ERREGELA.findall(lerroa):
                erreferentziak.append((kokapena, erref, zenbakia))

        # Derrigorrezko atalak: kapituluak soilik
        if erlatiboa.parts[0] == "kapituluak":
            for atala in DERRIGORREZKO_ATALAK:
                if atala not in testua:
                    txostena.oharra(kokapena, f"falta da: '{atala}'")

    for kokapena, erref, zenbakia in erreferentziak:
        if erref not in ids:
            txostena.errorea(
                f"{kokapena}:{zenbakia}", f"erreferentzia hautsiak: @{erref}"
            )

    # Hiztegia sinkronizatuta dagoen
    try:
        sys.path.insert(0, str(ROOT / "tresnak"))
        import hiztegia  # noqa: E402

        errenkadak = hiztegia.bildu()
        edukia = hiztegia.sortu(errenkadak)
        sortua = ROOT / "eranskinak" / "a-terminologia.qmd"
        if not sortua.exists() or sortua.read_text(encoding="utf-8") != edukia:
            txostena.errorea(
                "eranskinak/a-terminologia.qmd",
                "zaharkituta; exekutatu `python tresnak/hiztegia.py`",
            )
    except SystemExit as exc:  # hiztegia.bildu()-k errorea ematen duenean
        txostena.errorea("terminologia/hiztegia.csv", str(exc))

    zorroztu = "--zorroztu" in sys.argv

    print(f"Aztertutako fitxategiak: {len(list(fitxategiak()))}")
    print(f"IDak: {len(ids)}  Erreferentziak: {len(erreferentziak)}")

    if txostena.oharrak:
        print(f"\nOharrak ({len(txostena.oharrak)}):")
        for oharra in txostena.oharrak:
            print(f"  - {oharra}")

    if txostena.erroreak:
        print(f"\nAkatsak ({len(txostena.erroreak)}):")
        for errorea in txostena.erroreak:
            print(f"  x {errorea}")
        return 1

    if zorroztu and txostena.oharrak:
        print("\n--zorroztu: oharrak errore gisa hartu dira.")
        return 1

    print("\nOK: ez da arazorik aurkitu.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
