#!/usr/bin/env python3
"""Hiztegia -> eranskin.qmd

`terminologia/hiztegia.csv` irakurri eta `eranskinak/a-terminologia.qmd`
sortzen du. Fitxategi hori ez da eskuz editatu behar: CSVa da iturri bakarra.

Erabilera:
    python tresnak/hiztegia.py
    python tresnak/hiztegia.py --check    # egiaztatu soilik, ez idatzi
"""

from __future__ import annotations

import csv
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CSV_PATH = ROOT / "terminologia" / "hiztegia.csv"
OUT_PATH = ROOT / "eranskinak" / "a-terminologia.qmd"

KATEGORIA_ORDENA = [
    "Oinarrizko kontzeptuak",
    "Konposizioa",
    "Tipoak eta funtzioak",
    "Erreferentzia",
    "Semantika lexikoa",
    "Gertakariak",
    "Modalitatea",
    "Pragmatika",
    "Testua eta egitura",
]

EGOERA_MARKA = {
    "onartua": "",
    "berria": "†",
    "berrikusteko": "‡",
}


def bildu():
    """CSV fitxategia irakurri eta errenkaden zerrenda itzuli."""
    if not CSV_PATH.exists():
        sys.exit(f"Errorea: ez da aurkitu {CSV_PATH}")

    errenkadak = []
    # utf-8-sig: BOM-a kudeatzeko (Excel-ek sorturiko fitxategiak)
    with CSV_PATH.open(encoding="utf-8-sig", newline="") as fh:
        irakurlea = csv.DictReader(fh, delimiter=";")
        beharrezkoak = {"eu", "en", "definizioa", "oharrak", "egoera", "kategoria"}
        falta = beharrezkoak - set(irakurlea.fieldnames or [])
        if falta:
            sys.exit(f"Errorea: zutabe hauek falta dira: {sorted(falta)}")

        for zenbakia, errenkada in enumerate(irakurlea, start=2):
            garbia = {k: (v or "").strip() for k, v in errenkada.items() if k}
            if not garbia.get("eu"):
                continue
            if garbia["egoera"] not in EGOERA_MARKA:
                sys.exit(
                    f"Errorea ({CSV_PATH.name}:{zenbakia}): "
                    f"egoera ezezaguna: {garbia['egoera']!r}"
                )
            garbia["_lerroa"] = zenbakia
            errenkadak.append(garbia)

    # Termino bikoiztuak detektatu
    ikusiak = {}
    for e in errenkadak:
        gakoa = e["eu"].casefold()
        if gakoa in ikusiak:
            sys.exit(
                f"Errorea ({CSV_PATH.name}:{e['_lerroa']}): "
                f"termino bikoiztua: {e['eu']!r}"
            )
        ikusiak[gakoa] = e

    return errenkadak


def ordena_gakoa(testua: str) -> str:
    """Azentu eta diakritikoak kenduta, ordena alfabetiko egonkorra lortzeko."""
    forma = unicodedata.normalize("NFD", testua.casefold())
    return "".join(c for c in forma if unicodedata.category(c) != "Mn")


def ihes(testua: str) -> str:
    """Markdown taulan erabiltzeko prestatu."""
    return testua.replace("|", "\\|").replace("\n", " ")


def sortu(errenkadak) -> str:
    kategoriatan = {}
    for e in errenkadak:
        kategoriatan.setdefault(e["kategoria"], []).append(e)

    kategoria_guztiak = KATEGORIA_ORDENA + sorted(
        k for k in kategoriatan if k not in KATEGORIA_ORDENA
    )

    atalak = []
    atalak.append(
        "---\n"
        'title: "Terminologia"\n'
        "---\n"
        "\n"
        "Hiztegi honek liburuan erabilitako terminologia biltzen du, euskaraz eta\n"
        "ingelesez. Termino bakoitzak definizio labur bat du, eta, beharrezkoa\n"
        "denean, erabilera-ohar bat.\n"
    )
    atalak.append(
        "::: {.callout-note title=\"Nola irakurri taula hau\" appearance=\"simple\"}\n"
        "Zutabeak: euskarazko terminoa, ingelesezko parekidea, definizioa eta\n"
        "oharrak. Termino baten ondoren **†** badago, terminoa proposamena da\n"
        "oraindik, eta **‡** badago, berrikusteko dago.\n"
        ":::\n"
    )
    atalak.append(
        f"Guztira **{len(errenkadak)}** termino daude, "
        f"{len([k for k in kategoria_guztiak if k in kategoriatan])} ataletan "
        "banatuta.\n"
    )

    for kategoria in kategoria_guztiak:
        if kategoria not in kategoriatan:
            continue
        terminoak = sorted(kategoriatan[kategoria], key=lambda e: ordena_gakoa(e["eu"]))
        atalak.append(f"\n## {kategoria}\n")
        atalak.append("| Euskara | Ingelesez | Definizioa | Oharrak |")
        atalak.append("|:---|:---|:---|:---|")
        for e in terminoak:
            marka = EGOERA_MARKA[e["egoera"]]
            eu = ihes(e["eu"]) + marka
            atalak.append(
                f"| **{eu}** | {ihes(e['en'])} | {ihes(e['definizioa'])} | "
                f"{ihes(e['oharrak'])} |"
            )

    atalak.append("\n## Aurkibide alfabetikoa\n")
    atalak.append("| Euskara | Ingelesez |")
    atalak.append("|:---|:---|")
    for e in sorted(errenkadak, key=lambda e: ordena_gakoa(e["eu"])):
        atalak.append(f"| {ihes(e['eu'])}{EGOERA_MARKA[e['egoera']]} | {ihes(e['en'])} |")

    atalak.append(
        "\n::: {.callout-warning title=\"Fitxategi sortua\" appearance=\"simple\"}\n"
        "Orri hau automatikoki sortzen da `terminologia/hiztegia.csv` fitxategitik.\n"
        "Ez editatu eskuz: aldaketak CSVan egin eta gero exekutatu\n"
        "`python tresnak/hiztegia.py`.\n"
        ":::\n"
    )

    return "\n".join(atalak) + "\n"


def main() -> int:
    errenkadak = bildu()
    edukia = sortu(errenkadak)

    if "--check" in sys.argv:
        lehendik = OUT_PATH.read_text(encoding="utf-8") if OUT_PATH.exists() else ""
        if lehendik != edukia:
            print(
                "Errorea: eranskinak/a-terminologia.qmd zaharkituta dago. "
                "Exekutatu `python tresnak/hiztegia.py`."
            )
            return 1
        print(f"OK: hiztegia eguneratuta ({len(errenkadak)} termino).")
        return 0

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(edukia, encoding="utf-8", newline="\n")
    print(f"Sortua: {OUT_PATH.relative_to(ROOT)} ({len(errenkadak)} termino)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
