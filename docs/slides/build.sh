#!/usr/bin/env bash
# docs/slides/*.md（Marp）を PDF / HTML に変換する。
#
#   ./docs/slides/build.sh            # dist/slides/ に出力
#   ./docs/slides/build.sh out_dir    # 出力先を指定
#
# 必要なもの: Node.js 18+ と Chrome / Chromium（PDF 変換に使う）。
# Chrome の場所を自動検出できない場合は CHROME_PATH で指定する。
# root で実行する場合は CHROME_NO_SANDBOX=1 を付ける。
# npx を使わず既存の marp コマンドを使う場合は MARP_BIN=/path/to/marp を指定する。
set -euo pipefail

MARP_CLI_VERSION="4.5.0"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SLIDES_DIR="$REPO_ROOT/docs/slides"
OUT_DIR="${1:-$REPO_ROOT/dist/slides}"

mkdir -p "$OUT_DIR"
cd "$REPO_ROOT"

# MARP_BIN を指定するとその実行ファイルを使う（例: グローバルインストール済みの marp）。
# --no-stdin と </dev/null: 標準入力が TTY でない環境（CI やスクリプト内）で
# marp-cli が stdin の入力を待ち続けて止まるのを防ぐ。
marp() {
  if [ -n "${MARP_BIN:-}" ]; then
    "$MARP_BIN" --no-stdin --theme-set "$SLIDES_DIR/themes" --html --allow-local-files "$@" </dev/null
  else
    npx -y "@marp-team/marp-cli@${MARP_CLI_VERSION}" --no-stdin \
      --theme-set "$SLIDES_DIR/themes" --html --allow-local-files "$@" </dev/null
  fi
}

for src in "$SLIDES_DIR"/*.md; do
  name="$(basename "$src" .md)"
  [ "$name" = "README" ] && continue
  echo "==> $name"
  # --pdf-outlines: 見出しとページから PDF のしおり（目次）を作る
  marp "$src" --pdf --pdf-outlines -o "$OUT_DIR/$name.pdf"
  marp "$src" --html -o "$OUT_DIR/$name.html"
done

echo "Output: $OUT_DIR"
ls -la "$OUT_DIR"
