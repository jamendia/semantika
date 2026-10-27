#!/usr/bin/env python3
"""Terminology consistency checks for the Basque textbook.

Usage: python check_terms.py <termbase.csv> <chapters-dir> [--release]

Checks:
 1. 'eu_rejected' stems (semicolon-separated, case-insensitive substrings) must not appear in the text.
 2. Pending markers ('.term-pending', '.exm-pending') are listed per file.
 3. With --release: exit 1 if any pending marker remains or any term still has status
    'proposed' or 'provisional'.
Also prints how often each preferred term (eu_preferred, matched as a substring) is used: a
quick way to spot terms that are in the termbase but never used (or used under another form).
Code blocks and YAML front matter are ignored.
"""
import csv
import re
import sys
from pathlib import Path


def prose_lines(text):
    in_code, fence, in_yaml = False, "", False
    lines = text.splitlines()
    for n, l in enumerate(lines, 1):
        if n == 1 and l.strip() == "---":
            in_yaml = True
            continue
        if in_yaml:
            if l.strip() in ("---", "..."):
                in_yaml = False
            continue
        f = re.match(r"^\s*(`{3,})(.*)$", l)
        if f:
            if not in_code:
                in_code, fence = True, f.group(1)
            elif f.group(1).startswith(fence) and not f.group(2).strip():
                in_code = False
            continue
        if not in_code:
            yield n, l


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    release = "--release" in sys.argv
    if len(args) != 2:
        print(__doc__)
        return 2
    tb_path, ch_dir = Path(args[0]), Path(args[1])
    with tb_path.open(encoding="utf-8", newline="") as fh:
        terms = list(csv.DictReader(fh))
    files = sorted(ch_dir.rglob("*.qmd"))
    problems = 0
    usage = {t["id"]: 0 for t in terms}
    pending = {}
    for f in files:
        for n, line in prose_lines(f.read_text(encoding="utf-8")):
            low = line.lower()
            if "term-pending" in low or "exm-pending" in low:
                pending.setdefault(str(f), []).append(n)
            for t in terms:
                for rej in filter(None, (r.strip().lower() for r in (t.get("eu_rejected") or "").split(";"))):
                    if rej in low:
                        print(f"[REJECTED] {f}:{n}: '{rej}' (use '{t['eu_preferred']}', id {t['id']})")
                        problems += 1
                pref = (t.get("eu_preferred") or "").strip().lower()
                if pref and pref in low:
                    usage[t["id"]] += 1
    for f, ns in pending.items():
        print(f"[PENDING] {f}: {len(ns)} marker line(s), e.g. lines {ns[:5]}")
    unresolved = [t for t in terms if (t.get("status") or "").strip() in ("proposed", "provisional")]
    for t in unresolved:
        print(f"[STATUS] {t['id']} '{t['en']}' -> '{t['eu_preferred']}' is {t['status']}")
    unused = [t for t in terms if usage[t["id"]] == 0]
    print(f"\n{len(terms)} terms, {len(files)} files, {problems} rejected-variant hits, "
          f"{sum(len(v) for v in pending.values())} pending marker lines, {len(unused)} terms never used as written.")
    if release and (problems or pending or unresolved):
        print("RELEASE CHECK FAILED")
        return 1
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
