#!/usr/bin/env python3
"""EUC-JP（など非 UTF-8）のソースを、エンコーディングを壊さずに読み書きする。

Claude Code の Edit / Write は UTF-8 以外のファイルを扱えないため、
移行対象のファイルはこのスクリプト経由で変更する。

  eucjp.py cat FILE              FILE を UTF-8 にして標準出力へ
  eucjp.py write FILE            標準入力（UTF-8）を EUC-JP で FILE に書く
  eucjp.py replace FILE [--all]  標準入力の置換ブロックを適用する
  eucjp.py check FILE...         EUC-JP として正しく、UTF-8 との往復で変化しないか確認

replace の入力形式（ブロックは複数並べてよい）:
  <<<<<<< OLD
  置換前（UTF-8）
  =======
  置換後（UTF-8）
  >>>>>>> NEW
既定では OLD はファイル中にちょうど 1 回現れなければならない（--all で全置換）。

文字コードは環境変数 SRC_ENCODING で変えられる（既定 EUC-JP。例: CP932）。
"""
import os
import sys

ENC = os.environ.get("SRC_ENCODING", "EUC-JP")


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
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
