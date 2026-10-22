#!/usr/bin/env python3
"""特性テストの結果を expectations.tsv（旧環境の挙動の推定）と照合する。

  usage: check-expectations.py <actual_dir> [expectations.tsv]

expectations.tsv の 3 列目:
  文字列        応答（UTF-8 に変換したもの）に含まれること
  re:正規表現   行単位（re.M）の正規表現にマッチすること
  !文字列 / !re:正規表現   含まれない（マッチしない）こと
  must の不一致があれば終了コード 1。legacy の不一致は「差分（分類が要る）」として表示するだけ。
"""
import os
import re
import sys

actual = sys.argv[1]
exp = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "expectations.tsv")
def _src_encoding(default="EUC-JP"):
    """環境変数 SRC_ENCODING、なければリポジトリ直下の .upgrade.env の SRC_ENCODING、なければ default。"""
    if os.environ.get("SRC_ENCODING"):
        return os.environ["SRC_ENCODING"]
    d = os.path.dirname(os.path.abspath(__file__))
    while d != os.path.dirname(d):
        p = os.path.join(d, ".upgrade.env")
        if os.path.exists(p):
            for line in open(p, encoding="utf-8"):
                m = re.match(r"\s*SRC_ENCODING\s*=\s*(\S+)", line)
                if m:
                    return m.group(1)
        d = os.path.dirname(d)
    return default


enc = _src_encoding()
must_ng, legacy_ng, n = [], [], 0
for line in open(exp, encoding="utf-8"):
    line = line.rstrip("\n")
    if not line or line.startswith("#"):
        continue
    case, kind, pat = line.split("\t", 2)
    n += 1
    path = os.path.join(actual, case + ".txt")
    body = open(path, "rb").read().decode(enc, errors="replace") if os.path.exists(path) else ""
    neg = pat.startswith("!")
    p = pat[1:] if neg else pat
    ok = bool(re.search(p[3:], body, re.M)) if p.startswith("re:") else p in body
    ok = ok != neg
    if not ok:
        (must_ng if kind == "must" else legacy_ng).append(f"{case}: {pat}")
print(f"期待値 {n} 件: must の不一致 {len(must_ng)} 件、legacy（旧の推定）との差分 {len(legacy_ng)} 件")
for m in must_ng:
    print("  NG     " + m)
for m in legacy_ng:
    print("  差分   " + m)
sys.exit(1 if must_ng else 0)
