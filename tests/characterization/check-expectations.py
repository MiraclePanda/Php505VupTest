#!/usr/bin/env python3
"""特性テストの結果を expectations.tsv（旧環境の挙動の推定）と照合する。

  usage: check-expectations.py <actual_dir> [expectations.tsv]
  must の不一致があれば終了コード 1。legacy の不一致は「差分（分類が要る）」として表示するだけ。
"""
import os
import re
import sys

actual = sys.argv[1]
exp = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "expectations.tsv")
enc = os.environ.get("SRC_ENCODING", "EUC-JP")
must_ng, legacy_ng, n = [], [], 0
for line in open(exp, encoding="utf-8"):
    line = line.rstrip("\n")
    if not line or line.startswith("#"):
        continue
    case, kind, pat = line.split("\t", 2)
    n += 1
    path = os.path.join(actual, case + ".txt")
    body = open(path, "rb").read().decode(enc, errors="replace") if os.path.exists(path) else ""
    ok = re.search(pat[3:], body, re.M) if pat.startswith("re:") else pat in body
    if not ok:
        (must_ng if kind == "must" else legacy_ng).append(f"{case}: {pat}")
print(f"期待値 {n} 件: must の不一致 {len(must_ng)} 件、legacy（旧の推定）との差分 {len(legacy_ng)} 件")
for m in must_ng:
    print("  NG     " + m)
for m in legacy_ng:
    print("  差分   " + m)
sys.exit(1 if must_ng else 0)
