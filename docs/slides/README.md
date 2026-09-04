# docs/slides — README のスライド版（Marp）

`../../README.md` の内容を [Marp](https://marp.app/) でスライド化した資料です。Markdown 単体より視覚的に追いやすいよう、表・フロー図・コールアウトで再構成しています。

| ファイル | 内容 |
|---|---|
| `roBa-guide.md` | スライド原稿（Marp Markdown） |
| `roBa-guide.pdf` | 生成された PDF（`main` への push 時に GitHub Actions が更新） |
| `themes/roba.css` | カスタムテーマ |
| `build.sh` | PDF / HTML を作るスクリプト |

## PDF を読む

- 最新版: [`roBa-guide.pdf`](./roBa-guide.pdf)
- `main` 以外のブランチや PR では、Actions の **Build Slides (Marp)** の artifact `slides` に PDF と HTML が入っています。

## ローカルでビルドする

Node.js 18 以上と Chrome / Chromium が必要です。

```bash
./docs/slides/build.sh            # dist/slides/roBa-guide.pdf と .html を生成
```

編集しながらプレビューするなら:

```bash
npx -y @marp-team/marp-cli@4.5.0 -s docs/slides   # http://localhost:8080 でライブプレビュー
```

VS Code の拡張 [Marp for VS Code](https://marketplace.visualstudio.com/items?itemName=marp-team.marp-vscode) を使う場合は、設定 `markdown.marp.themes` に `docs/slides/themes/roba.css` を追加するとテーマが反映されます。

## 編集のルール

原稿の書き方・レイアウト部品（2 カラム、フロー図、コールアウト）の使い方は `.claude/skills/marp-slides/SKILL.md` にまとめています。要点:

- README が正本。README を変えたら対応するスライドも更新する。
- 1 スライド 1 トピック。長い節は `(1/2)` `(2/2)` に分ける。
- PDF は手で commit しない（CI が生成して commit する）。
