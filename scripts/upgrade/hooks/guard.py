#!/usr/bin/env python3
"""PreToolUse フック: 移行作業で触ってはいけないものを守る。

- app/（移行元）と tests/characterization/golden/（旧環境の記録）への書き込みを拒否
- 解答キー docs/sample-app-traps.md の参照を拒否（評価の公正のため）。
  振り返り（upgrade-retro スキル）で採点するときだけ .work/allow-answer-key を作って解除する
- Edit / Write での EUC-JP ファイル編集を拒否し、scripts/upgrade/eucjp.py を案内する

拒否は終了コード 2 + 標準エラー（Claude に理由が伝わる）。
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
PROTECTED_WRITE = ("app/", "tests/characterization/golden/")
ANSWER_KEY = "docs/sample-app-traps.md"


def deny(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)


def rel(path):
    if not path:
        return ""
    return os.path.relpath(os.path.abspath(os.path.join(ROOT, path)), ROOT)


def main():
    data = json.load(sys.stdin)
    tool = data.get("tool_name", "")
    inp = data.get("tool_input", {}) or {}
    answer_key_open = os.path.exists(os.path.join(ROOT, ".work", "allow-answer-key"))

    if tool in ("Edit", "Write", "MultiEdit", "NotebookEdit"):
        p = rel(inp.get("file_path") or inp.get("notebook_path"))
        if p.startswith(PROTECTED_WRITE):
            deny(f"{p} は書き換え禁止です（app/ は移行元、golden/ は旧環境の記録）。移行先は newapp/ に書いてください。")
        if p.startswith("newapp/app/") and os.path.exists(os.path.join(ROOT, p)):
            try:
                open(os.path.join(ROOT, p), "rb").read().decode("utf-8")
            except UnicodeDecodeError:
                deny(f"{p} は UTF-8 ではありません。scripts/upgrade/eucjp.py replace / write で編集してください。")

    blob = json.dumps(inp, ensure_ascii=False)
    if ANSWER_KEY in blob or "sample-app-traps" in blob:
        if not answer_key_open:
            deny("docs/sample-app-traps.md は移行の評価中は参照禁止です（CLAUDE.md）。採点は upgrade-retro スキルで行います。")

    if tool == "Bash":
        cmd = inp.get("command", "")
        # app/ や golden/ への書き込みらしいコマンド
        targets = r"(?<![\w/.-])(\./)?(app/|tests/characterization/golden/)"
        if re.search(r"eucjp\.py\s+(write|replace)\s+" + targets, cmd) \
                or re.search(r"(>|>>|\btee\b|\bsed\b[^|;&]*\s-i[^|;&]*\s|\b(rm|perl\s+-p?i)\b[^|;&]*)\s*" + targets, cmd) \
                or re.search(r"\b(cp|mv)\b[^|;&]*\s" + targets + r"\S*\s*($|[|;&])", cmd):  # cp/mv の宛先
            deny("app/ と tests/characterization/golden/ は書き換え禁止です。移行先は newapp/ です。")


if __name__ == "__main__":
    main()
