#!/usr/bin/env python3
"""EUC-JP（など非 UTF-8）のソースを、エンコーディングを壊さずに読み書きする。

Claude Code の Edit / Write は UTF-8 以外のファイルを扱えないため、
移行対象のファイルはこのスクリプト経由で変更する。

  eucjp.py cat FILE              FILE を UTF-8 にして標準出力へ
  eucjp.py write FILE            標準入力（UTF-8）を EUC-JP で FILE に書く
  eucjp.py replace FILE [--all] [--regex]  標準入力の置換ブロックを適用する
  eucjp.py check FILE...         EUC-JP として正しく、UTF-8 との往復で変化しないか確認
  eucjp.py detect FILE|DIR...    文字コードを推定する（UTF-8 / EUC-JP / CP932 / ASCII）。全体の結論を最後の行に出す

replace の入力形式（ブロックは複数並べてよい）:
  <<<<<<< OLD
  置換前（UTF-8）
  =======
  置換後（UTF-8）
  >>>>>>> NEW
既定では OLD はファイル中にちょうど 1 回現れなければならない（--all で全置換）。
--regex では OLD を Python の正規表現（MULTILINE）、NEW を置換文字列（\\1 などの後方参照可）として扱う。
  例: 全ファイルの ereg( を preg_match に機械的に置き換えるのではなく、一致件数を確かめながら使うこと（件数を表示する）。

文字コードはリポジトリ直下の .upgrade.env（SRC_ENCODING=...）か環境変数 SRC_ENCODING で変えられる（既定 EUC-JP。例: CP932）。
名前は EUC-JP 用だが、Shift_JIS（CP932）など他の文字コードにも使える。
"""
import os
import re
import sys

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


ENC = _src_encoding()


def read(path):
    with open(path, "rb") as f:
        data = f.read()
    try:
        return data.decode(ENC)
    except UnicodeDecodeError as e:
        sys.exit(f"{path}: {ENC} として読めません: {e}")


def write(path, text):
    try:
        data = text.encode(ENC)
    except UnicodeEncodeError as e:
        sys.exit(f"{path}: {ENC} で表せない文字があります: {e}")
    with open(path, "wb") as f:
        f.write(data)


def guess(data):
    """バイト列の文字コードを推定する。日本語のレガシー文字コードの判別に絞った簡易版。"""
    if all(b < 0x80 for b in data):
        return "ASCII"
    cands = []
    for enc in ("UTF-8", "EUC-JP", "CP932"):
        try:
            data.decode(enc)
            cands.append(enc)
        except UnicodeDecodeError:
            pass
    if "UTF-8" in cands:
        return "UTF-8"
    if len(cands) == 1:
        return cands[0]
    if not cands:
        return "不明"
    # 両方で読める場合: 半角カナ（EUC-JP の 0x8E 前置）や、かなの出現率で決める
    def score(enc):
        t = data.decode(enc)
        return sum(1 for c in t if "\u3040" <= c <= "\u30ff" or "\u4e00" <= c <= "\u9fff" or c in "、。「」（）")
    return max(cands, key=score)


def iter_files(paths):
    for p in paths:
        if os.path.isdir(p):
            for d, _, fs in os.walk(p):
                for f in sorted(fs):
                    yield os.path.join(d, f)
        else:
            yield p


def parse_blocks(src):
    blocks, lines, i = [], src.split("\n"), 0
    while i < len(lines):
        if lines[i].rstrip() != "<<<<<<< OLD":
            if lines[i].strip():
                sys.exit(f"置換ブロックの外に文字があります（{i + 1} 行目）: {lines[i]!r}")
            i += 1
            continue
        i += 1
        old, new = [], []
        while i < len(lines) and lines[i].rstrip() != "=======":
            old.append(lines[i]); i += 1
        i += 1
        while i < len(lines) and lines[i].rstrip() != ">>>>>>> NEW":
            new.append(lines[i]); i += 1
        if i >= len(lines):
            sys.exit(">>>>>>> NEW がありません")
        i += 1
        blocks.append(("\n".join(old), "\n".join(new)))
    if not blocks:
        sys.exit("置換ブロックがありません")
    return blocks


def main():
    flags = [a for a in sys.argv[1:] if a.startswith("--")]
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if len(args) < 2:
        sys.exit(__doc__)
    cmd, path = args[0], args[1]
    if cmd == "cat":
        sys.stdout.write(read(path))
    elif cmd == "write":
        write(path, sys.stdin.read())
    elif cmd == "replace":
        text = read(path)
        replace_all = "--all" in flags
        for old, new in parse_blocks(sys.stdin.read()):
            if "--regex" in flags:
                rx = re.compile(old, re.M)
                n = len(rx.findall(text))
                if n == 0:
                    sys.exit(f"{path}: 一致しません: {old}")
                if n > 1 and not replace_all:
                    sys.exit(f"{path}: {n} 箇所に一致します（--all で全置換）: {old}")
                text = rx.sub(new, text)
                print(f"{path}: {n} 箇所を置換")
                continue
            n = text.count(old)
            if n == 0:
                sys.exit(f"{path}: 見つかりません:\n{old}")
            if n > 1 and not replace_all:
                sys.exit(f"{path}: {n} 箇所にあります（一意になるよう前後を含めるか --all）:\n{old}")
            text = text.replace(old, new)
        write(path, text)
        print(f"{path}: 置換しました")
    elif cmd == "check":
        bad = 0
        for p in args[1:]:
            data = open(p, "rb").read()
            try:
                if data.decode(ENC).encode(ENC) != data:
                    raise ValueError("往復で変化")
            except (UnicodeError, ValueError) as e:
                print(f"NG {p}: {e}")
                bad += 1
        sys.exit(1 if bad else 0)
    elif cmd == "detect":
        seen = {}
        for p in iter_files(args[1:]):
            if not re.search(r"\.(php|inc|tpl|html?|js|css|sql|txt|csv|ini|conf)$", p, re.I):
                continue
            g = guess(open(p, "rb").read())
            seen.setdefault(g, []).append(p)
            print(f"{g}\t{p}")
        legacy = [k for k in seen if k not in ("ASCII",)]
        print("結論: " + (legacy[0] if len(legacy) == 1 else "混在 " + ",".join(sorted(legacy)) if legacy else "ASCII のみ"))
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
