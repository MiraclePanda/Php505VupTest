#!/usr/bin/env python3
"""評価用の複製の移行結果を採点する（評価者専用）。

  usage: python3 eval/score.py <eval_copy_dir> [--app eval/apps/app2] [--no-hidden-tests]
    --app を付けると、そのアプリの checks.tsv、hidden/run.sh、hidden/expectations.tsv、encoding で採点する

1. checks.tsv の客観チェック（コード・棚卸し・DB 移行）
2. 隠しテスト: このリポジトリの特性テスト（run.sh）と期待値（expectations.tsv）を複製に一時的に置き、
   verify.sh を実行して must の一致数と PHP エラーを数える（終わったら複製のファイルを元に戻す）
"""
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)


def read(path, enc="utf-8"):
    try:
        return open(path, "rb").read().decode(enc, errors="replace")
    except OSError:
        return ""


def gather(target, kind, enc="euc_jp"):
    if kind == "code":
        out = []
        for d, _, fs in os.walk(os.path.join(target, "newapp", "app")):
            out += [read(os.path.join(d, f), enc) for f in fs if f.endswith((".php", ".inc", ".tpl", ".phtml"))]
        # コメント中の旧い書き方（「旧: $code{0}」など）で誤判定しないよう、コメントを除く
        code = re.sub(r"/\*.*?\*/", "", "\n".join(out), flags=re.S)
        return re.sub(r"(?m)(^|[^:\"'])//.*$", r"\1", code)
    if kind == "inventory":
        return read(os.path.join(target, "newapp", "docs", "inventory.md"))
    if kind == "db":
        d = os.path.join(target, "newapp", "db")
        return "\n".join(read(os.path.join(d, f)) for f in os.listdir(d)) if os.path.isdir(d) else ""
    if kind.startswith("file:"):
        return read(os.path.join(target, kind[5:]))
    return read(os.path.join(target, kind))


def main():
    target = os.path.abspath(sys.argv[1])
    app = None
    if "--app" in sys.argv:
        app = os.path.abspath(os.path.join(ROOT, sys.argv[sys.argv.index("--app") + 1]))
    checks = os.path.join(app, "checks.tsv") if app else os.path.join(HERE, "checks.tsv")
    enc = "euc_jp"
    if app and os.path.exists(os.path.join(app, "encoding")):
        enc = open(os.path.join(app, "encoding")).read().strip()
    results = {}
    for line in open(checks, encoding="utf-8"):
        if not line.strip() or line.startswith("#"):
            continue
        item, kind, mode, pat = line.rstrip("\n").split("\t", 3)
        hit = re.search(pat, gather(target, kind, enc), re.M) is not None
        ok = hit if mode == "must" else not hit
        results.setdefault(item, []).append((ok, f"{kind} {mode} /{pat}/"))
    passed = [k for k, v in results.items() if all(ok for ok, _ in v)]
    print(f"## 客観チェック: {len(passed)}/{len(results)} 項目")
    for k, v in results.items():
        if not all(ok for ok, _ in v):
            print(f"  NG {k}: " + "; ".join(d for ok, d in v if not ok))

    if "--no-hidden-tests" in sys.argv:
        return
    tests = os.path.join(target, "tests", "characterization")
    backup = {}
    src_dir = os.path.join(app, "hidden") if app else os.path.join(ROOT, "tests", "characterization")
    for name in ("run.sh", "expectations.tsv"):
        p = os.path.join(tests, name)
        backup[name] = open(p, "rb").read() if os.path.exists(p) else None
        shutil.copy(os.path.join(src_dir, name), p)
    env = dict(os.environ)
    if app:
        env["SRC_ENCODING"] = {"cp932": "CP932", "euc_jp": "EUC-JP"}.get(enc, enc)
    try:
        out = subprocess.run(["scripts/upgrade/verify.sh", "hidden-eval"], cwd=target,
                             capture_output=True, text=True, errors="replace", env=env).stdout
    finally:
        for name, data in backup.items():
            p = os.path.join(tests, name)
            if data is None:
                os.remove(p)
            else:
                open(p, "wb").write(data)
    print("## 隠しテスト（" + ("app2 の hidden/" if app else "このリポジトリの特性テスト") + " + 期待値）")
    for l in out.splitlines():
        if re.search(r"期待値|NG |差分 |応答にエラー|RESULT|ソースが出力|PHP (Warning|Fatal|Deprecated)", l):
            print("  " + l.strip())


if __name__ == "__main__":
    main()
