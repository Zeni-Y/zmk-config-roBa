# CLAUDE.md — zmk-config-roBa

roBa（トラックボール付き分割キーボード）用の ZMK ファームウェア設定リポジトリ。
人間向けの説明は `README.md` にすべて書いてある。ここには AI エージェント / 開発者が作業するときの約束事だけを書く。

## リポジトリの役割分担

| パス | 役割 | 触るときの注意 |
|---|---|---|
| `config/roBa.keymap` | キーマップの正本（Single Source of Truth） | レイヤーは末尾に追加。Layer 4 (MOUSE) / 5 (SCROLL) の番号は `&trackball` から参照されるので固定 |
| `boards/shields/roBa/roBa_R.conf` | トラックボール設定（CPI / Auto Mouse timeout / ZMK Studio） | 変更すると再ビルド・再書き込みが必要 |
| `build.yaml` | ビルド対象 | 通常変更しない |
| `keymap-drawer/` | キーマップ図（Actions の Draw Keymap が生成） | 手で編集しない |
| `docs/slides/` | README をスライド化した Marp 資料と PDF | 下記「スライド」を参照 |
| `.github/workflows/build.yml` | push ごとにファームウェアをビルド | ZMK 公式の再利用ワークフロー |
| `.github/workflows/draw.yml` | キーマップ図の再生成（手動） | |
| `.github/workflows/slides.yml` | スライドを PDF / HTML 化し、main では PDF を commit し直す | |

## ドキュメントの方針

- `README.md` が正本。手順・仕様の変更は必ず README に反映する。
- `docs/slides/roBa-guide.md` は README の内容を **視覚的に読みやすく再構成したもの**。README を大きく変えたら対応するスライドも更新する（章番号・節番号は README と揃える）。
- `docs/slides/roBa-guide.pdf` は CI が生成して commit する成果物。手で編集せず、ローカルで作った PDF も commit しない（CI と差分が出るため）。

## スライド（Marp）

- 原稿: `docs/slides/roBa-guide.md`、テーマ: `docs/slides/themes/roba.css`、ビルド: `docs/slides/build.sh`
- スライドを追加・修正するときは `.claude/skills/marp-slides/SKILL.md` の手順とデザインルールに従う。
- ローカルで確認する:

  ```bash
  ./docs/slides/build.sh                 # dist/slides/ に PDF と HTML
  # レイアウト崩れを目視確認するときは 1 枚ずつ PNG にする
  npx -y @marp-team/marp-cli@4.5.0 docs/slides/roBa-guide.md --theme-set docs/slides/themes \
    --html --allow-local-files --images png -o dist/slides/roBa-guide.png
  ```

  Chrome / Chromium が必要。見つからない場合は `CHROME_PATH=/path/to/chrome`、root で動かすなら `CHROME_NO_SANDBOX=1` を付ける。

## ビルドとテスト

- ファームウェア: push すると `build.yml` が走る。ローカルビルド環境は用意していない。
- `.keymap` を変更したら各レイヤーの `bindings` が 43 個であること、Combo の `key-positions` が 0〜42 であることを確認する。
- スライドを変更したら `./docs/slides/build.sh` が通ることと、はみ出しがないことを PNG で確認する。

## コミット

- 変更は小さく、メッセージは具体的に（README 11.2 節）。例: `mouse: move left click to J`、`slides: add snipe mode example`。
- 生成物（`keymap-drawer/*.svg`、`docs/slides/*.pdf`）は CI が commit する。手動で更新しない。
