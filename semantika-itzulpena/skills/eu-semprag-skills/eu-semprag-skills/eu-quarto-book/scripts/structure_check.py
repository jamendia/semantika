#!/usr/bin/env python3
"""Compare the structural skeleton of English source .qmd files with their Basque translations.

Usage: python structure_check.py <src-dir> <eu-dir> [--para-tolerance 0.15]

For every .qmd under <src-dir>, finds the same relative path under <eu-dir> and compares:
headings (levels), labels/IDs, cross-references, citations, code-cell engines and labels,
divs/callouts, shortcodes, images, and (loosely) paragraph counts.
Exit code 0 = all match, 1 = mismatches (or missing files).
"""
import re
import sys
from collections import Counter
from pathlib import Path

XREF_PREFIXES = ("sec", "fig", "tbl", "eq", "lst", "exm", "thm", "lem", "cor", "prp", "cnj", "def", "exr")


def parse(text):
    out = {k: [] for k in ("headings", "labels", "xrefs", "cites", "shortcodes",
                           "divs", "code", "images", "yaml_keys")}
    lines = text.splitlines()
    i = 0
    if lines and lines[0].strip() == "---":
        end = next((k for k in range(1, len(lines)) if lines[k].strip() in ("---", "...")), None)
        if end:
            for l in lines[1:end]:
                m = re.match(r"^([\w-]+):", l)
                if m:
                    out["yaml_keys"].append(m.group(1))
            i = end + 1
    in_code, fence, paras, in_para = False, "", 0, False
    for l in lines[i:]:
        f = re.match(r"^\s*(`{3,})(.*)$", l)
        if f:
            if not in_code:
                in_code, fence = True, f.group(1)
                info = f.group(2).strip()
                out["code"].append(info.split()[0] if info else "")
            elif f.group(1).startswith(fence) and not f.group(2).strip():
                in_code = False
            continue
        if in_code:
            m = re.match(r"^#\|\s*label:\s*(\S+)", l)
            if m:
                out["labels"].append(m.group(1))
            continue
        h = re.match(r"^(#{1,6})\s", l)
        if h:
            out["headings"].append(len(h.group(1)))
        out["labels"] += re.findall(r"\{[^}]*#([\w:-]+)[^}]*\}", l)
        for x in re.findall(r"@([A-Za-z][\w:.-]*)", l):
            x = x.rstrip(".:-")
            if x.split("-")[0] in XREF_PREFIXES and "-" in x:
                out["xrefs"].append(x)
            else:
                out["cites"].append(x)
        out["shortcodes"] += [re.sub(r"\s+", " ", s) for s in re.findall(r"\{\{<\s*([\w-]+)", l)]
        d = re.match(r"^\s*:{3,}\s*\{?([^\s}]*)", l)
        if d and d.group(1):
            out["divs"].append(d.group(1))
        out["images"] += re.findall(r"!\[[^\]]*\]\(([^)\s]+)", l)
        if l.strip() and not h and not l.lstrip().startswith((":::", "|", "<!--")):
            if not in_para:
                paras += 1
                in_para = True
        else:
            in_para = False
    out["paragraphs"] = paras
    return out


def diff(name, a, b):
    ca, cb = Counter(a), Counter(b)
    if ca == cb:
        return []
    msgs = []
    for k in sorted(set(ca) | set(cb), key=str):
        if ca[k] != cb[k]:
            msgs.append(f"  {name}: {k!r} source={ca[k]} translation={cb[k]}")
    return msgs


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    tol = 0.15
    if "--para-tolerance" in sys.argv:
        tol = float(sys.argv[sys.argv.index("--para-tolerance") + 1])
        args = [a for a in args if a != str(tol)]
    if len(args) != 2:
        print(__doc__)
        return 2
    src, eu = Path(args[0]), Path(args[1])
    bad = 0
    for sf in sorted(src.rglob("*.qmd")):
        rel = sf.relative_to(src)
        tf = eu / rel
        if not tf.exists():
            print(f"[MISSING] {rel}: no translation file")
            bad += 1
            continue
        s, t = parse(sf.read_text(encoding="utf-8")), parse(tf.read_text(encoding="utf-8"))
        msgs, warns = [], []
        for key in ("headings", "labels", "xrefs", "cites", "shortcodes", "divs", "code", "images", "yaml_keys"):
            msgs += diff(key, s[key], t[key])
        if s["paragraphs"] and abs(s["paragraphs"] - t["paragraphs"]) / s["paragraphs"] > tol:
            warns.append(f"  paragraphs (warning only): source={s['paragraphs']} translation={t['paragraphs']}")
        if msgs:
            bad += 1
            print(f"[DIFF] {rel}")
            print("\n".join(msgs + warns))
        else:
            print(f"[OK]   {rel}")
            if warns:
                print("\n".join(warns))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
