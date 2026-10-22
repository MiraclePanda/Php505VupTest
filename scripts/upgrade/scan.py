#!/usr/bin/env python3
"""ルールカタログ（.claude/skills/php-upgrade/rules/*.md）の detect パターンでソースを走査する。

  scan.py <dir> [--rule R01] [--format md|tsv]

出力は「候補」。detect は広めに拾うので、該当するかは目視で確定すること。
ソースは SRC_ENCODING（既定 EUC-JP）で読み、UTF-8 で出力する。
"""
import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RULES_DIR = os.path.join(ROOT, ".claude", "skills", "php-upgrade", "rules")
EXTS = (".php", ".inc", ".phtml", ".tpl", ".html")
ENC = os.environ.get("SRC_ENCODING", "EUC-JP")


def load_rules():
    rules = []
    for name in sorted(os.listdir(RULES_DIR)):
        if not re.match(r"R\d+.*\.md$", name):
            continue
        text = open(os.path.join(RULES_DIR, name), encoding="utf-8").read()
        m = re.match(r"---\n(.*?)\n---\n", text, re.S)
        if not m:
            continue
        meta, detect, in_detect = {}, [], False
        for line in m.group(1).split("\n"):
            if in_detect and re.match(r"\s+-\s+'", line):
                detect.append(re.search(r"'(.*)'\s*$", line).group(1).replace("''", "'"))
                continue
            in_detect = line.startswith("detect:")
            kv = re.match(r"(\w+):\s*(.*)$", line)
            if kv and not in_detect:
                meta[kv.group(1)] = kv.group(2)
        meta["detect"] = [re.compile(p) for p in detect]
        meta["file"] = name
        rules.append(meta)
    return sorted(rules, key=lambda r: int(r.get("order", 999)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("target")
    ap.add_argument("--rule")
    ap.add_argument("--format", default="md", choices=["md", "tsv"])
    a = ap.parse_args()

    files = []
    if os.path.isfile(a.target):
        files = [a.target]
    else:
        for d, _, fs in os.walk(a.target):
            files += [os.path.join(d, f) for f in fs if f.endswith(EXTS)]
    files.sort()

    total = 0
    for rule in load_rules():
        if a.rule and rule["id"] != a.rule:
            continue
        hits = []
        for path in files:
            text = open(path, "rb").read().decode(ENC, errors="replace")
            for no, line in enumerate(text.split("\n"), 1):
                if any(p.search(line) for p in rule["detect"]):
                    hits.append((path, no, line.strip()))
        total += len(hits)
        if a.format == "tsv":
            for h in hits:
                print(f"{rule['id']}\t{h[0]}\t{h[1]}\t{h[2]}")
            continue
        print(f"## {rule['id']} {rule['title']}（{len(hits)} 件）\n")
        if hits:
            print("| 場所 | 行 |\n|---|---|")
            for path, no, line in hits:
                print(f"| `{path}:{no}` | `{line.replace('|', '&#124;')[:120]}` |")
            print()
    if a.rule and total:
        sys.exit(1)


if __name__ == "__main__":
    main()
