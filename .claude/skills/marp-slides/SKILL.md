---
name: marp-slides
description: docs/slides/ の Marp スライド（roBa-guide.md）を追加・修正・再構成し、はみ出しがないことを確認する。README の内容をスライド化する、スライドのレイアウトを直す、PDF を作る、テーマを調整する、といった依頼のときに使う。
---

# marp-slides — README をスライドにする

このリポジトリでは `README.md` が正本で、`docs/slides/roBa-guide.md` はそれを **Marp** でスライド化したもの。
GitHub Actions（`.github/workflows/slides.yml`）が PDF / HTML を生成し、`main` では `docs/slides/roBa-guide.pdf` を commit し直す。

## ファイル

| パス | 内容 |
|---|---|
| `docs/slides/roBa-guide.md` | スライド原稿（Marp Markdown） |
| `docs/slides/themes/roba.css` | カスタムテーマ `roba`（Marp Core の `default` を継承） |
| `docs/slides/build.sh` | PDF / HTML を作るスクリプト（CI とローカル共通） |
| `docs/slides/README.md` | 人間向けの使い方 |

## 手順

1. README の該当章を読み、スライドにする情報を選ぶ（全文転記ではなく、表・図・コード・注意点を中心に再構成する）。
2. `roBa-guide.md` を編集する。章の順番と番号は README と揃える。
3. PNG に書き出して **すべての変更したスライドを目視確認** する。

   ```bash
   mkdir -p dist/slides
   npx -y @marp-team/marp-cli@4.5.0 --no-stdin docs/slides/roBa-guide.md --theme-set docs/slides/themes \
     --html --allow-local-files --images png -o dist/slides/roBa-guide.png
   # dist/slides/roBa-guide.001.png ... を画像として開いて確認
   ```

   Chrome が見つからないときは `CHROME_PATH=...`、root なら `CHROME_NO_SANDBOX=1` を付ける。
4. はみ出し（本文がフッター行 y≈650px を越える）、極端に縮小されたコードブロック、空きすぎたスライドを直す。
5. `./docs/slides/build.sh` で PDF が作れることを確認する。PDF 自体は commit しない（CI が commit する）。

## デザインルール（テーマ `roba` の前提）

- **1 スライド 1 トピック。** README の 1 節が長いときは `（1/2）（2/2）` に分ける。
- 本文は 24px 基準。スライドに入る目安は、全幅なら本文 12 行 / 表 12 行 / コード 22 行、2 カラムなら各 14 行程度。
- **横に並べられるものは 2 カラムにする**: `<div class="columns">`（等分）、`columns w-left`（3:2）、`columns w-right`（2:3）、`columns-3`（3 等分）。カラム内は空行で挟めば Markdown が書ける。
- **手順の流れはフロー図にする**: `<div class="flow">` に `<div>` を並べると矢印付きの横フロー、`flow vertical` で縦フロー。強調は `class="good"`（緑）/ `class="alt"`（橙）。
- **注意・補足はコールアウトにする**: `<div class="warn">`（注意）、`<div class="tip">`、`<div class="note">`。Markdown の `>` 引用も補足枠になる。
- 表は `|` の Markdown 表をそのまま使う（テーマが全幅・ゼブラにする）。行が多いときは `<div class="small">` で包む。
- 長い行のコードは自動で縮小される（`@auto-scaling`）。縮小しすぎて読めなくなる場合は、狭いカラムに入れず全幅の独立スライドにする。
- 各章の最初のスライドで `<!-- header: N. 章タイトル -->` を設定する（以降のスライドに引き継がれる）。
- 表紙・まとめは `<!-- _class: lead -->`、Part 区切りは `<!-- _class: divider -->` + `<p class="part">Part N</p>`。
- 縦長の画像は `<div class="figure clip" style="height: 440px">` で上部だけ見せる。
- 参照は「6.7 節」「8 章」のように README の番号で書く（スライド内リンクは張らない）。

## やってはいけないこと

- README にない情報をスライドだけに書く（正本は README）。
- `docs/slides/roBa-guide.pdf` を手動で更新・commit する。
- Marp Core のテーマを直接編集する。変更は `themes/roba.css` に加える。
