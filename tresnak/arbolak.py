#!/usr/bin/env python3
"""Zuhaitz sintaktikoak sortu (Forest -> SVG).

`kapituluak/*.qmd` eta beste fitxategietan dauden `{.tree #id}` blokeak
bilatu, bakoitzaren edukia (parentesi etiketatuak) hartu, LaTeX
dokumentu autonomo batean muntatu, `lualatex`-ekin PDFra konpilatu eta
`pdftocairo`-rekin SVGra bihurtu `assets/arbolak/<id>.svg` sortzeko.

Erabilera:
    python tresnak/arbolak.py            # sortu/guneratu guztiak
    python tresnak/arbolak.py --check    # egiaztatu soilik (CI)
"""

from __future__ import annotations

import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "arbolak"
TREE_RE = re.compile(r":::\s*\{\.tree\s+#([\w-]+)\}\s*\n(.*?)\n:::", re.DOTALL)

PREAMBLE = r"""
\documentclass[border=4pt]{standalone}
\usepackage{fontspec}
\usepackage[basque]{babel}
\usepackage[linguistics]{forest}
\forestset{
  default preamble={
    for tree={
      parent anchor=south,
      child anchor=north,
      font=\small,
      edge={semithick},
      l sep+=1.2ex,
      s sep+=1.5ex,
      inner sep=2pt,
      align=center
    }
  }
}
\begin{document}
\begin{forest}
%s
\end{forest}
\end{document}
"""


def find_trees():
    trees = {}
    for qmd in ROOT.rglob("*.qmd"):
        if any(part in {".git", "_site", ".quarto"} for part in qmd.parts):
            continue
        text = qmd.read_text(encoding="utf-8")
        for match in TREE_RE.finditer(text):
            tid = match.group(1)
            content = match.group(2).strip()
            if tid in trees and trees[tid] != content:
                print(f"ABISUA: {tid} bikoiztua edukia desberdinarekin")
            trees[tid] = content
    return trees


def compile_tree(tid, content):
    ASSETS.mkdir(parents=True, exist_ok=True)
    svg_path = ASSETS / f"{tid}.svg"
    tex = PREAMBLE % content

    with tempfile.TemporaryDirectory() as tmp:
        tmpdir = Path(tmp)
        tex_file = tmpdir / f"{tid}.tex"
        tex_file.write_text(tex, encoding="utf-8")
        # lualatex
        r = subprocess.run(
            ["lualatex", "-interaction=nonstopmode", "-halt-on-error", tex_file.name],
            cwd=tmpdir,
            capture_output=True,
            text=True,
        )
        if r.returncode != 0:
            print(f"ERROREA {tid}: lualatex huts egin du")
            print(r.stdout[-1500:])
            return False
        pdf_file = tmpdir / f"{tid}.pdf"
        if not pdf_file.exists():
            print(f"ERROREA {tid}: ez da PDFrik sortu")
            return False
        # pdftocairo -> svg
        r2 = subprocess.run(
            ["pdftocairo", "-svg", str(pdf_file), str(svg_path)],
            capture_output=True,
            text=True,
        )
        if r2.returncode != 0 or not svg_path.exists():
            print(f"ERROREA {tid}: pdftocairo huts egin du")
            print(r2.stderr[-800:])
            return False
    print(f"Sortua: {svg_path.relative_to(ROOT)}")
    return True


def main():
    check = "--check" in sys.argv
    trees = find_trees()
    if not trees:
        print("Ez da zuhaitzik aurkitu.")
        return 0

    missing = []
    for tid, content in trees.items():
        svg_path = ASSETS / f"{tid}.svg"
        if check:
            if not svg_path.exists():
                missing.append(tid)
            continue
        if not compile_tree(tid, content):
            return 1

    if check:
        if missing:
            print(f"ERROREA: SVG falta dira: {missing}")
            return 1
        print(f"OK: {len(trees)} zuhaitz, SVG guztiak daude.")
        return 0

    print(f"Amaituta: {len(trees)} zuhaitz prozesatu.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
