# zmk-config-roBa

roBa（トラックボール付き分割キーボード）用の ZMK ファームウェア設定リポジトリです。

<img src="keymap-drawer/roBa.svg">

この README では、**GitHub 上の `config/roBa.keymap` を「正本（Single Source of Truth）」として設定を育てる**ための手順をまとめます。
Keymap Editor での編集方法、`.keymap` の読み書きに必要な基本概念、Mod-Tap や Layer-Tap などの機能の使い方と具体例、roBa 固有のトラックボール設定、ビルド・書き込み手順まで、この 1 ファイルで一通り分かるようにしています。

> **一言でまとめると: ZMK Studio は試す場所、GitHub の `roBa.keymap` は残す場所。**

---

## 目次

1. [リポジトリ構成](#1-リポジトリ構成)
2. [運用方針](#2-運用方針)
3. [初回セットアップ](#3-初回セットアップ)
4. [Keymap Editor の使い方](#4-keymap-editor-の使い方)
5. [`.keymap` の基本概念](#5-keymap-の基本概念)
6. [機能の使い方と具体例](#6-機能の使い方と具体例)
7. [現在のキーマップ構成](#7-現在のキーマップ構成)
8. [トラックボールの設定](#8-トラックボールの設定)
9. [ビルドと書き込み](#9-ビルドと書き込み)
10. [ZMK Studio との付き合い方](#10-zmk-studio-との付き合い方)
11. [設定を育てる運用 Tips](#11-設定を育てる運用-tips)
12. [トラブルシューティング](#12-トラブルシューティング)
13. [チートシート](#13-チートシート)
14. [参考資料](#14-参考資料)

---

## 1. リポジトリ構成

```text
zmk-config-roBa/
├── config/
│   ├── roBa.keymap        ← 最重要: キーマップ本体（レイヤー / Combo / Macro / Auto Mouse 指定）
│   ├── roBa.json          ← Keymap Editor 用の物理レイアウト情報
│   └── west.yml           ← ZMK 本体と PMW3610 ドライバの取得元
├── boards/shields/roBa/
│   ├── roBa.dtsi          ← 物理レイアウト・マトリクス定義（通常触らない）
│   ├── roBa_R.overlay     ← 右側（トラックボール側）のハード定義
│   ├── roBa_R.conf        ← 右側の設定: CPI / Auto Mouse timeout / Studio など
│   ├── roBa_L.overlay     ← 左側（ロータリーエンコーダ側）のハード定義
│   └── roBa_L.conf        ← 左側の設定
├── build.yaml             ← GitHub Actions でビルドするターゲット一覧
├── keymap-drawer/
│   ├── roBa.svg           ← 上に表示しているキーマップ図
│   └── roBa.yaml          ← 図の生成に使う中間ファイル
└── .github/workflows/
    ├── build.yml          ← push ごとにファームウェアをビルド
    └── draw.yml           ← キーマップ図を再生成（手動実行）
```

普段編集するのは次の 3 つだけです。

| ファイル | 役割 | 編集手段 |
|---|---|---|
| `config/roBa.keymap` | キー割り当て・レイヤー・Mod-Tap・Combo・Macro・Auto Mouse Layer の指定 | Keymap Editor または手書き |
| `boards/shields/roBa/roBa_R.conf` | CPI、Auto Mouse のタイムアウト、スクロール感度、ZMK Studio の有効化 | 手書き |
| `build.yaml` | どのファームウェアをビルドするか | 手書き（通常は変更不要） |

### 設定の 2 層構造

roBa の設定には「ファームウェアに焼き込まれる設定」と「ZMK Studio で本体に保存される設定」の 2 種類があります。

```text
GitHub の roBa.keymap
        ↓ GitHub Actions でビルド
ファームウェア上の「Stock Keymap」
        ↓
ZMK Studio で編集（任意）
        ↓
キーボード本体の persistent storage に「Runtime Keymap」として保存
```

**一度 ZMK Studio でキーマップを触ると、その後 `.keymap` を変更して再ビルド・書き込みしても Studio 側の保存済み設定が優先されます。**
`.keymap` の内容に戻すには ZMK Studio の **Restore Stock Settings** が必要です（[10 章](#10-zmk-studio-との付き合い方)）。

---

## 2. 運用方針

```text
GitHub の zmk-config-roBa
        │
        ├── config/roBa.keymap            ← キーマップの正本
        ├── boards/shields/roBa/roBa_R.conf ← トラックボール等の正本
        └── build.yaml
              ↓
         GitHub Actions
              ↓
            UF2
              ↓
       roBa 本体へ書込み
```

| ツール | 用途 | 推奨度 |
|---|---|:---:|
| GitHub + `roBa.keymap` | 正式な設定・バックアップ・変更履歴 | ◎ |
| Keymap Editor | `roBa.keymap` を GUI で編集して GitHub に直接 commit | ◎ |
| 手書き編集 | Combo / Macro / カスタム Behavior / `.conf` などの高度な編集 | ○ |
| ZMK Studio | 一時的な試行・動作確認（正本にはしない） | △ |

**原則: 「手元の roBa がどうなっているか」ではなく「GitHub の `main` に何が書かれているか」を正式な設定とみなします。**
これを守ると、故障・紛失・買い替えがあっても同じ操作体系を再現できます。

---

## 3. 初回セットアップ

### 3.1 公式リポジトリを Fork する

1. GitHub にログインする
2. 公式リポジトリ https://github.com/kumamuk-git/zmk-config-roBa を開く
3. 右上の **Fork** → **Create fork**
4. `<あなたのユーザー名>/zmk-config-roBa` ができるので、以降はこちらを編集する

### 3.2 GitHub Actions を有効化する

Fork 直後は Actions が無効になっていることがあります。

1. 自分の `zmk-config-roBa` を開く
2. **Actions** タブを開く
3. `I understand my workflows, go ahead and enable them` が出たらクリック

### 3.3 ローカルにも Clone する（推奨）

GitHub 上と Keymap Editor だけでも運用できますが、`.conf` の編集や Tag 付けをするならローカル Clone があると便利です。

```bash
git clone https://github.com/<YOUR_GITHUB_ID>/zmk-config-roBa.git
cd zmk-config-roBa

# 公式更新を取り込みやすくするため upstream を追加
git remote add upstream https://github.com/kumamuk-git/zmk-config-roBa.git
git remote -v
#   origin    → 自分の Fork
#   upstream  → roBa 公式
```

### 3.4 すでに ZMK Studio で設定している場合

**いきなり Restore Stock Settings を押さないでください。** Studio から `.keymap` へ Export する機能はまだありません。

```text
1. ZMK Studio の全レイヤーをスクリーンショットで記録する
   （Key Press / Mod-Tap / Layer-Tap / Mouse Key / Bluetooth / Transparent と None の区別）
2. レイヤー名と番号も記録する（番号は Auto Mouse などから参照される）
3. Keymap Editor で roBa.keymap に同じ配置を再現する
4. Save（= GitHub に commit）
5. GitHub Actions のビルド成功を確認
6. UF2 を書き込む
7. 最後に ZMK Studio で Restore Stock Settings
8. GitHub 側の設定が反映されたことを確認
```

---

## 4. Keymap Editor の使い方

Keymap Editor は、ブラウザ上で `.keymap` を GUI 編集し、そのまま GitHub に commit できるツールです。

https://nickcoutsos.github.io/keymap-editor/

### 4.1 自分の Fork を接続する

1. Keymap Editor を開く
2. 上部のタブで **GitHub** を選ぶ
3. **Login with GitHub** を押す
4. **Authorize Keymap Editor** で認可する
5. GitHub App のインストール画面で、自分の `zmk-config-roBa` へのアクセスを許可する（`Only select repositories` で対象を絞ってよい）
6. Editor に戻り、**Repository** で `zmk-config-roBa`、**Branch** で `main` を選ぶ
7. `config/roBa.keymap` が読み込まれ、キーボードの図が表示される

物理レイアウトは `config/roBa.json` から読まれます。このファイルを消したり名前を変えたりすると Editor がレイアウトを見つけられなくなります。

### 4.2 画面の見方

```text
┌─ レイヤー一覧 ─┐  ┌──────── キーボード図 ────────┐
│ 0 default_layer│  │  現在選択中のレイヤーの各キー   │
│ 1 FUNCTION     │  │  クリックすると編集ポップアップ │
│ 2 NUM          │  │                               │
│ 3 ARROW        │  └───────────────────────────────┘
│ 4 MOUSE        │
│ 5 SCROLL       │  [Combos] [Macros] [Behaviors] などの追加パネル
│ 6 layer_6      │
└────────────────┘                    [Save] ボタン
```

- **レイヤー一覧** から編集したいレイヤーを選ぶ
- **キーをクリック** すると、そのキーの Behavior とパラメータを編集するポップアップが開く
- 各キーは「Behavior（`&kp` など）」+「パラメータ（`A` など）」の組み合わせで表示される

### 4.3 キーを変更する

1. 変更したいキーをクリックする
2. 左側で **Behavior** を選ぶ（`&kp` Key Press、`&mt` Mod-Tap、`&lt` Layer-Tap、`&mo`、`&to`、`&tog`、`&mkp`、`&bt`、`&trans`、`&none` など）
3. 右側でパラメータを選ぶ
   - `&kp` ならキーコード一覧から選ぶ（検索欄に `ENTER` や `F5` のように入力すると絞り込める）
   - `&mt` なら「修飾キー」と「タップ時のキー」の 2 つ
   - `&lt` なら「レイヤー」と「タップ時のキー」の 2 つ
4. 修飾キー付きのキー（例: `Ctrl+Shift+Tab`）は、キーコードを選んだ後に **modifier** のトグル（`LS` `LC` `LA` `LG` など）を押して重ねる
5. ポップアップを閉じると図に反映される（この時点ではまだ GitHub には保存されていない）

`roBa.keymap` に手書きで定義したカスタム Behavior（この repo なら `&lt_to_layer_0` と `&to_layer_0`）も Behavior 一覧に出てきます。

### 4.4 レイヤーを追加・名前変更・並べ替えする

- レイヤー一覧の **+** で新しいレイヤーを末尾に追加する
- レイヤー名をクリックすると名前を変更できる（`.keymap` のノード名になる）
- 並べ替えや削除もレイヤー一覧のボタンから行う

**注意: レイヤー番号は `.keymap` に書かれた順番で決まります。**
途中にレイヤーを挿入すると後続のレイヤー番号がずれ、`&lt 2 SPACE` のような番号指定や、`automouse-layer = <4>` などトラックボール側の参照が意図しないレイヤーを指すようになります。
新しいレイヤーは **末尾に追加する** のが安全です（詳細は [5.3 節](#53-レイヤーとレイヤー番号)）。

### 4.5 Combo を編集する

Editor には Combo を編集するパネルがあります。

1. **Combos** パネルを開く
2. 既存の Combo を選ぶか **+** で追加する
3. 同時押しするキーを図上でクリックして選ぶ（`key-positions` に対応）
4. 発動する Behavior を設定する（`bindings` に対応）

`timeout-ms` や `layers` のような細かい指定は手書きの方が確実です（[6.7 節](#67-combo同時押し)）。

### 4.6 Save の意味

Keymap Editor の **Save** は、単なるブラウザ内保存ではありません。

```text
Save
 ↓ commit メッセージを入力
GitHub の config/roBa.keymap に commit（選択中の branch）
 ↓
GitHub Actions が自動起動
 ↓
ファームウェア（UF2）が自動ビルドされる
```

つまり **Save = commit** です。ZMK Studio との最大の違いはここで、Save した時点で変更履歴が GitHub に残ります。

Save の際に、Editor は `.keymap` を整形し直します。手書きで追加した `&trackball { ... }` や `behaviors { ... }`、`macros { ... }`、コメントなどは保持されますが、インデントや列揃えは変わることがあります。

### 4.7 Editor でできること・できないこと

| やりたいこと | Editor | 手書き |
|---|:---:|:---:|
| キーの割り当て変更 | ◎ | ○ |
| Mod-Tap / Layer-Tap の設定 | ◎ | ○ |
| レイヤーの追加・名前変更 | ◎ | ○ |
| Combo の追加・変更 | ○ | ◎ |
| Macro の作成 | △ | ◎ |
| Hold-Tap の細かい設定（`tapping-term-ms` など） | × | ◎ |
| カスタム Behavior（Home Row Mods など） | × | ◎ |
| `&trackball { automouse-layer ... }` | × | ◎ |
| `.conf`（CPI / timeout） | × | ◎ |

Editor で編集した `.keymap` に、あとから手書きで Behavior を追加しても問題ありません。両方を組み合わせて使えます。

---

## 5. `.keymap` の基本概念

Keymap Editor だけでも運用できますが、`.keymap` を読めると「Editor が何をしているか」が分かり、Combo や Macro を安心して追加できます。

### 5.1 ファイルの全体像

```dts
#include <behaviors.dtsi>             // 標準 Behavior（&kp, &mt, &lt ...）
#include <dt-bindings/zmk/bt.h>       // BT_SEL などの定数
#include <dt-bindings/zmk/keys.h>     // キーコード（A, ENTER, F1 ...）
#include <dt-bindings/zmk/pointing.h> // MB1 などマウス関連の定数

&mt { ... };            // 標準 Behavior の挙動を変える（任意）
&trackball { ... };     // トラックボール: Auto Mouse / Scroll レイヤーの指定

/ {
    combos { ... };     // 同時押し
    macros { ... };     // マクロ
    behaviors { ... };  // カスタム Behavior

    keymap {
        compatible = "zmk,keymap";

        default_layer { bindings = < ... >; };   // Layer 0
        FUNCTION      { bindings = < ... >; };   // Layer 1
        ...
    };
};
```

### 5.2 Behavior とキーコード

各キーは **Behavior（何をするか）** と **パラメータ** の組み合わせです。

```dts
&kp A            // Key Press: A
&kp LS(A)        // Shift + A（修飾キーは関数のように重ねる）
&kp LC(LS(TAB))  // Ctrl + Shift + Tab
```

修飾キー関数:

| 関数 | 意味 |
|---|---|
| `LS()` / `RS()` | 左 / 右 Shift |
| `LC()` / `RC()` | 左 / 右 Ctrl |
| `LA()` / `RA()` | 左 / 右 Alt |
| `LG()` / `RG()` | 左 / 右 GUI（Windows / Command） |

よく使う Behavior:

| 表記 | 意味 | 例 |
|---|---|---|
| `&kp` | Key Press | `&kp A` |
| `&mt` | Mod-Tap（長押しで修飾、タップでキー） | `&mt LEFT_SHIFT Z` |
| `&lt` | Layer-Tap（長押しでレイヤー、タップでキー） | `&lt 2 SPACE` |
| `&mo` | Momentary Layer（押している間だけ） | `&mo 3` |
| `&to` | 指定レイヤーに切り替え（戻らない） | `&to 0` |
| `&tog` | レイヤーのトグル | `&tog 6` |
| `&sk` | Sticky Key（次の 1 キーだけ修飾） | `&sk LSHIFT` |
| `&sl` | Sticky Layer（次の 1 キーだけレイヤー） | `&sl 2` |
| `&trans` | 下位レイヤーを透過 | `&trans` |
| `&none` | 何もしない（下位も無視） | `&none` |
| `&mkp` | Mouse Key Press（クリック） | `&mkp MB1` |
| `&bt` | Bluetooth 操作 | `&bt BT_SEL 0` |
| `&bootloader` | ブートローダーに入る（書き込みモード） | `&bootloader` |
| `&caps_word` | 次の単語だけ大文字 | `&caps_word` |

キーコードの一覧は https://zmk.dev/docs/keymaps/list-of-keycodes にあります。

### 5.3 レイヤーとレイヤー番号

ZMK では `keymap { }` 内に書かれた **順番** でレイヤー番号が決まります。名前は人間向けのラベルで、番号指定には使えません。

```text
default_layer → 0
FUNCTION      → 1
NUM           → 2
ARROW         → 3
MOUSE         → 4
SCROLL        → 5
layer_6       → 6
```

レイヤーは重なって動作します。上位のレイヤーが有効なとき、`&trans` のキーは下のレイヤーの割り当てが使われます。

```text
Layer 4 (MOUSE):   trans  trans  MB1   MB3   MB2   trans
Layer 0 (default): H      J      K     L     '     ...
                   ──────────────────────────────────
実際の動作:         H      J      MB1   MB3   MB2   '
```

`&none` は「何も起きない」で、下のレイヤーも見ません。Auto Mouse 中に文字が誤入力されるのを防ぎたい場合に使います。

### 5.4 キー位置番号（Combo で使う）

Combo は「どのキーとどのキーを同時に押すか」を **位置番号** で指定します。番号は左上から右へ、行ごとに振られます（0 始まり、全 43 キー）。

```text
 0   1   2   3   4                     5   6   7   8   9
10  11  12  13  14  15            16  17  18  19  20  21
22  23  24  25  26  27            28  29  30  31  32  33
34  35  36  37  38  39            40  41              42
```

現在の default レイヤーに当てはめると次の通りです。

```text
 Q   W   E   R   T                     Y   U   I   O   P
 A   S   D   F   G  ⌘⇧S            -   H   J   K   L   '
 Z   X   C   V   B   :             ;   N   M   ,   .   /
Ctl Win Alt 変換 Spc 無変換        BS  Ent             Del
```

---

## 6. 機能の使い方と具体例

### 6.1 Mod-Tap（`&mt`）

**長押しすると修飾キー、短く押すとキー**になります。

```dts
&mt LEFT_SHIFT Z     // 長押し: Shift / タップ: z
&mt LCTRL ESCAPE     // 長押し: Ctrl  / タップ: Esc
&mt LGUI TAB         // 長押し: Win   / タップ: Tab
```

Keymap Editor では Behavior に `&mt` を選び、1 つ目に修飾キー、2 つ目にタップ時のキーを指定します。

この repo では Z キーが `&mt LEFT_SHIFT Z` になっており、左手小指を動かさずに Shift が押せます。

#### 判定を調整する

Mod-Tap は Hold-Tap の一種で、`.keymap` の先頭で挙動を変えられます。この repo では次の設定です。

```dts
&mt {
    flavor = "balanced";
    quick-tap-ms = <0>;
};
```

| プロパティ | 意味 | 既定値 |
|---|---|---|
| `tapping-term-ms` | この時間より長く押すと「長押し」扱い | 200 |
| `flavor` | 長押し / タップの判定方法（下表） | `hold-preferred` |
| `quick-tap-ms` | この時間内に同じキーを再度押すと必ずタップ扱い（連打・リピート用）。`0` や未設定で無効 | 無効 |
| `require-prior-idle-ms` | 直前のキー入力からこの時間以内なら必ずタップ扱い（速いタイピング中の誤爆防止） | 無効 |

| flavor | 挙動 |
|---|---|
| `hold-preferred` | `tapping-term-ms` を超えるか、他のキーが押されたら即「長押し」 |
| `balanced` | `tapping-term-ms` を超えるか、他のキーが押されて **離されたら**「長押し」。バランス型でおすすめ |
| `tap-preferred` | `tapping-term-ms` を超えたときだけ「長押し」。他のキーを押しても影響しない |
| `tap-unless-interrupted` | 他のキーが押されない限りタップ。押されたら長押し |

「Shift のつもりが z が出る」なら `tapping-term-ms` を短く、「z のつもりが Shift になる」なら長くします。

#### 具体例: Home Row Mods

ホームポジション（A S D F / J K L ;）に修飾キーを重ねる定番の構成です。左右で「反対側の手で押したときだけ長押しと判定する」カスタム Behavior を作ると誤爆が減ります。
`hold-trigger-key-positions` には [5.4 節](#54-キー位置番号combo-で使う) の位置番号を使います。

```dts
/ {
    behaviors {
        // 左手用: 右手側のキー（5〜9, 16〜21, 28〜33, 40〜42）と組み合わせたときだけ長押し
        hml: home_row_mod_left {
            compatible = "zmk,behavior-hold-tap";
            #binding-cells = <2>;
            bindings = <&kp>, <&kp>;
            flavor = "balanced";
            tapping-term-ms = <220>;
            quick-tap-ms = <150>;
            require-prior-idle-ms = <100>;
            hold-trigger-key-positions = <5 6 7 8 9 16 17 18 19 20 21 28 29 30 31 32 33 40 41 42>;
            hold-trigger-on-release;
        };

        // 右手用: 左手側のキーと組み合わせたときだけ長押し
        hmr: home_row_mod_right {
            compatible = "zmk,behavior-hold-tap";
            #binding-cells = <2>;
            bindings = <&kp>, <&kp>;
            flavor = "balanced";
            tapping-term-ms = <220>;
            quick-tap-ms = <150>;
            require-prior-idle-ms = <100>;
            hold-trigger-key-positions = <0 1 2 3 4 10 11 12 13 14 15 22 23 24 25 26 27 34 35 36 37 38 39>;
            hold-trigger-on-release;
        };
    };
};
```

default レイヤーの該当キーを次のように置き換えます。

```dts
&hml LGUI A   &hml LALT S   &hml LCTRL D   &hml LSHIFT F
&hmr RSHIFT J &hmr RCTRL K  &hmr RALT L    &hmr RGUI SQT
```

Keymap Editor では `&hml` / `&hmr` が Behavior 一覧に現れるので、パラメータの変更は GUI からもできます。

### 6.2 Layer-Tap（`&lt`）

**長押しするとレイヤー、短く押すとキー**になります。親指キーの定番です。

```dts
&lt 2 SPACE     // 長押し: Layer 2 (NUM) / タップ: Space
&lt 1 ENTER     // 長押し: Layer 1 (FUNCTION) / タップ: Enter
&lt 5 I         // 長押し: Layer 5 (SCROLL) / タップ: i
```

Keymap Editor では Behavior に `&lt` を選び、1 つ目にレイヤー、2 つ目にタップ時のキーを指定します。

`&mt` と同様に `&lt { tapping-term-ms = <180>; };` などで判定を調整できます。

#### 具体例: この repo のカスタム Layer-Tap

日本語入力用に「長押しでレイヤー、タップで **Layer 0 に戻ってから** 変換 / 無変換を送る」Behavior を定義しています。

```dts
macros {
    to_layer_0: to_layer_0 {
        compatible = "zmk,behavior-macro-one-param";
        #binding-cells = <1>;
        bindings = <&to 0 &macro_param_1to1 &kp MACRO_PLACEHOLDER>;
    };
};

behaviors {
    lt_to_layer_0: lt_to_layer_0 {
        compatible = "zmk,behavior-hold-tap";
        #binding-cells = <2>;
        bindings = <&mo>, <&to_layer_0>;   // 長押し: &mo <layer> / タップ: &to_layer_0 <key>
        tapping-term-ms = <200>;
    };
};
```

```dts
&lt_to_layer_0 6 INT_HENKAN     // 長押し: Layer 6 / タップ: Layer 0 に戻して 変換
&lt_to_layer_0 3 INT_MUHENKAN   // 長押し: Layer 3 / タップ: Layer 0 に戻して 無変換
```

`&to` で別のレイヤーに固定した後でも、このキーをタップすれば必ず default に戻れるようになっています。

### 6.3 レイヤー切り替え（`&mo` / `&to` / `&tog` / `&sl`）

```dts
&mo 3     // 押している間だけ Layer 3
&to 6     // Layer 6 に切り替え（戻すには別のキーで &to 0）
&tog 6    // 押すたびに Layer 6 の ON / OFF を切り替え
&sl 2     // 次の 1 キーだけ Layer 2（Sticky Layer）
```

`&to` で移動したレイヤーには、戻るためのキーを必ず置いてください。この repo では `&to_layer_0` を親指のタップに割り当てて逃げ道にしています。

### 6.4 Sticky Key（`&sk`）

次の 1 キーだけ修飾を効かせます。「Shift を押しながら」が苦手な位置の修飾キーに便利です。

```dts
&sk LSHIFT    // 押して離し、次に a を押すと A
&sk LC(LALT)  // 次の 1 キーに Ctrl+Alt を付ける
```

### 6.5 Mouse Key（`&mkp` / `&msc` / `&mmv`）

`#include <dt-bindings/zmk/pointing.h>` と `CONFIG_ZMK_POINTING=y`（この repo では設定済み）が必要です。

```dts
&mkp MB1        // 左クリック
&mkp MB2        // 右クリック
&mkp MB3        // 中クリック
&mkp MB4        // 戻る
&mkp MB5        // 進む
&msc SCRL_UP    // ホイール上
&msc SCRL_DOWN  // ホイール下
&mmv MOVE_UP    // マウスカーソル移動（キーで動かす場合）
```

MOUSE レイヤー（Layer 4）の J / K / L に `MB1` / `MB3` / `MB2` を置いてあり、トラックボールを動かすと自動でこのレイヤーが有効になります（[8 章](#8-トラックボールの設定)）。

### 6.6 Bluetooth と bootloader（`&bt` / `&bootloader`）

```dts
&bt BT_SEL 0     // プロファイル 0 に切り替え（0〜4）
&bt BT_CLR       // 現在のプロファイルのペアリングを削除
&bt BT_CLR_ALL   // 全プロファイルのペアリングを削除
&bootloader      // 書き込みモードに入る（リセットボタンを押さなくてよい）
```

これらは誤操作を避けるため、専用の SYSTEM レイヤー（この repo では Layer 6）に置くのが定番です。

### 6.7 Combo（同時押し）

2 つ以上のキーを同時押ししたときに別のキーを出します。位置番号は [5.4 節](#54-キー位置番号combo-で使う) を参照してください。

```dts
/ {
    combos {
        compatible = "zmk,combos";

        tab {
            bindings = <&kp TAB>;
            key-positions = <11 12>;     // S + D
        };

        shift_tab {
            bindings = <&kp LS(TAB)>;
            key-positions = <12 13>;     // D + F
        };

        // レイヤーを限定したり、判定時間を変えたりする例
        esc_on_base {
            bindings = <&kp ESCAPE>;
            key-positions = <1 2>;       // W + E
            layers = <0>;                // Layer 0 のときだけ有効
            timeout-ms = <40>;           // 同時押しと見なす時間（既定 50ms）
            require-prior-idle-ms = <100>; // 速いタイピング中は発動しない
        };
    };
};
```

現在定義されている Combo:

| 同時押し | 位置 | 出力 |
|---|---|---|
| S + D | 11, 12 | Tab |
| D + F | 12, 13 | Shift + Tab |
| A + S | 10, 11 | Layer 0 に戻して 無変換 |
| L + ' | 20, 21 | `"` |
| C + V | 24, 25 | `=` |

### 6.8 Macro（マクロ）

複数のキー操作を 1 キーにまとめます。

```dts
/ {
    macros {
        // "hello" と打つ
        hello: hello {
            compatible = "zmk,behavior-macro";
            #binding-cells = <0>;
            bindings = <&kp H &kp E &kp L &kp L &kp O>;
        };

        // Ctrl を押したまま C → V を送る（押す / 離すを明示する例）
        ctrl_c_v: ctrl_c_v {
            compatible = "zmk,behavior-macro";
            #binding-cells = <0>;
            wait-ms = <30>;   // 各操作の間隔
            tap-ms = <30>;    // キーを押している時間
            bindings
                = <&macro_press &kp LCTRL>
                , <&macro_tap &kp C &kp V>
                , <&macro_release &kp LCTRL>
                ;
        };
    };
};
```

キーマップ側では `&hello` や `&ctrl_c_v` として使います。パラメータを受け取るマクロ（`zmk,behavior-macro-one-param`）の例は [6.2 節](#62-layer-taplt) の `to_layer_0` を参照してください。

### 6.9 ロータリーエンコーダ（`sensor-bindings`）

左側のロータリーエンコーダの動作はレイヤーごとに `sensor-bindings` で指定します。

```dts
default_layer {
    bindings = < ... >;
    sensor-bindings = <&inc_dec_kp PG_UP PAGE_DOWN>;          // 回転で PageUp / PageDown
};

ARROW {
    bindings = < ... >;
    sensor-bindings = <&inc_dec_kp LC(PAGE_UP) LC(PAGE_DOWN)>; // タブ切り替え
};
```

`sensor-bindings` を書かないレイヤーでは下位レイヤーの設定が使われます。音量にしたい場合は `&inc_dec_kp C_VOLUME_UP C_VOLUME_DOWN` です。

### 6.10 具体例: よくある変更

**Backspace と Delete を入れ替える**

```dts
// default_layer の親指行（変更前）
&kp BACKSPACE  &lt 1 ENTER  &kp DEL
// 変更後
&kp DEL        &lt 1 ENTER  &kp BACKSPACE
```

**Space の長押しを NUM ではなく ARROW にする**

```dts
&lt 2 SPACE   →   &lt 3 SPACE
```

**Esc を Ctrl との Mod-Tap にして左上に置く**

```dts
&kp Q   →   &mt LCTRL Q      // タップ: q / 長押し: Ctrl
```

**新しいレイヤーを追加する（末尾に）**

```dts
keymap {
    ...
    layer_6 { ... };

    // 新規: Layer 7
    MEDIA {
        bindings = <
&trans  &trans  &trans  &trans  &trans                      &kp C_PREV  &kp C_PP  &kp C_NEXT  &trans  &trans
&trans  &trans  &trans  &trans  &trans  &trans      &trans  &kp C_VOL_DN &kp C_MUTE &kp C_VOL_UP &trans &trans
&trans  &trans  &trans  &trans  &trans  &trans      &trans  &trans      &trans    &trans      &trans  &trans
&trans  &trans  &trans  &trans  &trans  &trans      &trans  &trans                                    &trans
        >;
    };
};
```

追加後、どこかのキーに `&mo 7` や `&lt 7 XXX` を置いて呼び出します。

---

## 7. 現在のキーマップ構成

| Layer | 名前 | 役割 | 呼び出し方 |
|---:|---|---|---|
| 0 | `default_layer` | 通常の文字入力 | 常時 |
| 1 | `FUNCTION` | F1〜F13 | Enter 長押し（`&lt 1 ENTER`） |
| 2 | `NUM` | テンキー配置の数字と記号 | Space 長押し（`&lt 2 SPACE`） |
| 3 | `ARROW` | 矢印、Home / End、タブ切り替え、Esc | 無変換 長押し（`&lt_to_layer_0 3`） |
| 4 | `MOUSE` | J / K / L に 左 / 中 / 右クリック | トラックボールを動かすと自動（Auto Mouse） |
| 5 | `SCROLL` | このレイヤー中はトラックボールがスクロール | I 長押し（`&lt 5 I`） |
| 6 | `layer_6` | Bluetooth 切り替え、`&bootloader`、`BT_CLR` | 変換 長押し（`&lt_to_layer_0 6`） |

その他:

- Z 長押しで Shift（`&mt LEFT_SHIFT Z`）
- NUM レイヤーでは `0` 長押しで Shift
- 左手親指行の内側キーは Win+Shift+S（Windows のスクリーンショット）
- ロータリーエンコーダ: 通常時 PageUp / PageDown、ARROW レイヤー中 Ctrl+PageUp / Ctrl+PageDown
- Combo は [6.7 節](#67-combo同時押し) を参照

**Layer 4 と 5 はトラックボールから番号で参照されているので、この 2 つの位置は固定しておく**と管理しやすくなります。

---

## 8. トラックボールの設定

### 8.1 Auto Mouse Layer と Scroll Layer（`roBa.keymap`）

```dts
&trackball {
    automouse-layer = <4>;   // トラックボールを動かすと Layer 4 を一時的に有効化
    scroll-layers = <5>;     // Layer 5 が有効な間はトラックボールの移動をスクロールにする
};
```

```text
トラックボールを動かす
      ↓
Layer 4 (MOUSE) が有効になる → J / K / L がクリックになる
      ↓
最後の入力から CONFIG_PMW3610_AUTOMOUSE_TIMEOUT_MS 経過
      ↓
Layer 4 が解除される

I を長押し（Layer 5）しながらトラックボールを動かす
      ↓
スクロールとして扱われる
```

MOUSE レイヤーは、文字キーを大量に上書きするより **クリックだけを必要な位置に置き、他は `&trans`** にすると扱いやすくなります。Auto Mouse 中の誤入力が気になるキーだけ `&none` にする設計も有効です。

`scroll-layers` は複数指定できます（例: `scroll-layers = <5 7>;`）。

### 8.2 `roBa_R.conf` の主な項目

トラックボール側（右）の `boards/shields/roBa/roBa_R.conf` で調整します。

| 設定 | 現在値 | 意味 |
|---|---|---|
| `CONFIG_PMW3610_CPI` | `400` | カーソル感度。大きいほど速い |
| `CONFIG_PMW3610_CPI_DIVIDOR` | `1` | CPI をこの値で割る（微調整用） |
| `CONFIG_PMW3610_AUTOMOUSE_TIMEOUT_MS` | `700` | 最後のトラックボール入力から Auto Mouse Layer を解除するまでの時間 |
| `CONFIG_PMW3610_SCROLL_TICK` | `16` | スクロール 1 段あたりに必要な移動量。大きいほどスクロールが遅い |
| `CONFIG_PMW3610_ORIENTATION_180` | `y` | センサーの取り付け向き |
| `CONFIG_PMW3610_INVERT_X` | `n` | X 方向を反転 |
| `CONFIG_PMW3610_INVERT_SCROLL_X` | `y` | 横スクロール方向を反転 |
| `CONFIG_PMW3610_MOVEMENT_THRESHOLD` | `0` | この移動量未満は無視（Auto Mouse の誤発動防止に使える） |
| `CONFIG_PMW3610_SMART_ALGORITHM` | `y` | センサーの追従性を改善するアルゴリズム |
| `CONFIG_PMW3610_POLLING_RATE_125_SW` | `y` | ポーリングレート 125Hz |
| `CONFIG_ZMK_STUDIO` | `y` | ZMK Studio を有効化 |

**例: Auto Mouse の継続時間を 1.5 秒にする**

```text
CONFIG_PMW3610_AUTOMOUSE_TIMEOUT_MS=1500
```

**例: 精密操作用の Snipe モードを使う**

`.conf` のコメントアウトを外し、`.keymap` で Snipe レイヤーを指定します。

```text
CONFIG_PMW3610_SNIPE_CPI=800
CONFIG_PMW3610_SNIPE_CPI_DIVIDOR=4
```

```dts
&trackball {
    automouse-layer = <4>;
    scroll-layers = <5>;
    snipe-layers = <7>;     // Layer 7 が有効な間は低感度になる
};
```

`.conf` を変更した場合は **ファームウェアの再ビルドと書き込み** が必要です。ZMK Studio からは変更できません。

### 8.3 実験的な機能: トラックボールで矢印キー

`roBa.keymap` にはコメントアウトされた `arrows { ... }` ブロックがあります。これを有効にすると、指定レイヤー中のトラックボール移動を矢印キーに変換できます。必要なときにコメントを外して試してください。

---

## 9. ビルドと書き込み

### 9.1 GitHub Actions でビルドする

Keymap Editor で Save するか、GitHub / ローカル Git から commit & push すると `.github/workflows/build.yml` が自動で走ります。

```text
編集
 ↓
Commit / Push
 ↓
GitHub Actions（Actions タブで進捗を確認）
 ↓
firmware artifact（zip）
```

1. 自分のリポジトリの **Actions** タブを開く
2. 最新の実行が緑（成功）になっているか確認する
3. 実行を開くと **Artifacts** に `firmware` があるのでダウンロードする
4. zip の中に次の UF2 が入っている

```text
roBa_R-seeeduino_xiao_ble-zmk.uf2
roBa_L-seeeduino_xiao_ble-zmk.uf2
settings_reset-seeeduino_xiao_ble-zmk.uf2
```

ビルドが赤（失敗）のときは、実行ログの末尾に `.keymap` の構文エラーの行番号が出ます。Keymap Editor で編集した直後に失敗する場合は、手書き部分（Combo の位置番号やカスタム Behavior）を疑ってください。

### 9.2 書き込む

1. 書き込みたい側の roBa を USB で PC に接続する
2. リセットボタンを **素早く 2 回** 押す（またはキーマップの `&bootloader` を押す）
3. `XIAO-SENSE` という名前の USB ドライブとして認識される
4. 対応する UF2 ファイルをドライブにコピーする
5. 自動的に再起動して書き込み完了

### 9.3 どちら側を書き換えるか

```text
ロータリーエンコーダ側 (L, Peripheral)
          ⇅ BLE
トラックボール側 (R, Central)
          ⇅ USB / BLE
          PC
```

| 変更内容 | R（トラックボール側） | L（エンコーダ側） |
|---|:---:|:---:|
| `roBa.keymap` のみ | ○ | 原則不要 |
| `roBa_R.conf`（CPI / Auto Mouse timeout） | ○ | ○ 推奨 |
| `roBa_L.conf` / overlay / shield | ○ | ○ |
| `west.yml`（ZMK バージョン更新） | ○ | ○ |

キーマップは Central（R）が処理するので、通常のキー変更は R 側だけ書き込めば反映されます。

### 9.4 `settings_reset` は通常使わない

`settings_reset` は Bluetooth のペアリング情報や内部設定をすべて消すためのファームウェアです。通常のキーマップ変更では不要です。

左右がつながらなくなった、PC とペアリングできなくなった、といったトラブル時に次の手順で使います。

1. 左右両方に `settings_reset` を書き込む
2. 左右両方に通常の `roBa_L` / `roBa_R` を書き込む
3. PC 側の Bluetooth 設定から roBa を削除して再ペアリングする

---

## 10. ZMK Studio との付き合い方

ZMK Studio（https://zmk.studio/）は、ブラウザから USB 経由で roBa に接続し、再ビルドなしでキーマップを変更できるツールです。この repo では R 側で有効になっています（`build.yaml` の `studio-rpc-usb-uart` と `CONFIG_ZMK_STUDIO=y`）。

### 10.1 使いどころ

「左クリックを J と F のどちらに置くか試したい」のような **短時間の試行** に向いています。

```text
Studio での変更 = 仮設定
GitHub に Commit = 正式設定
```

Studio で良い変更が見つかったら、**必ず Keymap Editor で `roBa.keymap` にも反映** してください。二重管理が面倒なら、キーマップ編集を Keymap Editor に一本化するのが最も安全です。

### 10.2 Studio でできないこと

- `.keymap` への Export / Import（2026-09 時点で Planned）
- Combo / Macro / カスタム Behavior の編集
- `.conf` の変更（CPI、Auto Mouse timeout）
- 変更履歴の管理

### 10.3 Restore Stock Settings の意味

Studio の **Restore Stock Settings** は「工場出荷時に戻す」というより、

> **現在のファームウェアに焼き込まれている `.keymap` の内容を、Studio の Runtime Keymap に再ロードする**

操作です。GitHub 側の `.keymap` を更新して新しい UF2 を書き込んだのに反映されないときは、これを実行します。

### 10.4 Studio でレイヤー名を見やすくする

Studio はレイヤーのノード名（`FUNCTION` など）を表示します。`display-name` を付けると任意の名前にできます。

```dts
layer_6 {
    display-name = "SYSTEM";
    bindings = < ... >;
};
```

---

## 11. 設定を育てる運用 Tips

### 11.1 標準フロー

```text
不便を感じる
  ↓
Keymap Editor で 1〜3 箇所変更
  ↓
Save（= commit）
  ↓
Actions 成功確認
  ↓
UF2 を R 側へ書込み
  ↓
必要なら Studio → Restore Stock Settings
  ↓
数日使う
  ↓
良ければ維持 / 悪ければ git revert
```

### 11.2 変更は小さく、メッセージは具体的に

```text
おすすめしない: update keymap
おすすめ:       mouse: move left click to J
                arrow: add Home/End
                base: swap Backspace and Delete
                trackball: extend automouse timeout to 1500ms
```

後で「どの変更が使いにくさの原因だったか」を追いやすくなります。レイヤー全体を一気に作り替えると、良し悪しの判断がつきません。

### 11.3 安定版に Tag を付ける

```bash
git tag -a v1.0 -m "first stable roBa keymap"
git push origin v1.0
```

さらに GitHub の **Releases** でその Tag から Release を作り、その時点の UF2 を添付しておくと、数年後でも再ビルドせずに書き戻せます。

### 11.4 大きな変更はブランチで

Home Row Mods 導入、レイヤー全面再設計、ZMK バージョン更新などはブランチを切ると安全です。

```bash
git switch -c experiment/home-row-mods
```

Keymap Editor の Branch 選択でこのブランチを選べば、GUI からブランチに commit できます。うまくいったら `main` に merge、駄目なら捨てます。

### 11.5 キーマップ図を更新する

`.github/workflows/draw.yml` を手動実行すると `keymap-drawer/roBa.svg` が再生成され、この README の図が最新になります。

1. **Actions** タブ → **Draw Keymap** を選ぶ
2. **Run workflow** を押す
3. 図を更新する commit が自動で追加される

push のたびに自動実行したい場合は `draw.yml` 内のコメントアウトを外します。

### 11.6 公式更新を取り込む

roBa 側の ZMK 対応やトラックボールドライバが更新されることがあります。GitHub の **Sync fork** ボタン、またはローカル Git で取り込みます。

```bash
# 復帰点を作ってから
git tag -a before-upstream-sync-$(date +%Y%m%d) -m "backup before upstream sync"
git push origin --tags

git fetch upstream
git log --oneline main..upstream/main   # 何が変わるか確認
git switch main
git merge upstream/main
```

自分の `roBa.keymap` と公式の `roBa.keymap` の両方が変わっていると Conflict します。慎重に運用するなら `boards/` `build.yaml` `config/west.yml` の更新だけ取り込み、`roBa.keymap` は自分のものを維持する方針もあります。

### 11.7 `KEYMAP_NOTES.md` を残す

キーマップだけでは「なぜこの位置にしたか」が残りません。リポジトリに `KEYMAP_NOTES.md` を追加して理由を書いておくと、半年後の自分に役立ちます。

```markdown
## Mouse layer
- J: Left Click / K: Middle Click / L: Right Click
- J は右手人差し指で押しやすいため左クリックにした

## ARROW layer
- HJKL は矢印にせず、Vim と競合しない配置を試している
```

---

## 12. トラブルシューティング

### `.keymap` を変更したのに反映されない

最有力候補は **ZMK Studio の Runtime Keymap が残っている** ことです。

1. Actions が成功していて、新しい UF2 を本当に書き込んだか確認する
2. R 側（トラックボール側）に書き込んだか確認する
3. ZMK Studio を開き **Restore Stock Settings** を実行する

Restore の前に、Studio 側にしかない未移行の設定がないか確認してください。

### トラックボールを動かしても MOUSE レイヤーにならない

1. `roBa.keymap` に `&trackball { automouse-layer = <4>; scroll-layers = <5>; };` があるか
2. Layer 4 が本当に MOUSE レイヤーか（途中にレイヤーを挿入して番号がずれていないか）
3. Layer 4 のクリック位置が `&mkp MB1` などになっているか
4. Studio の古い Runtime Keymap が残っていないか（Restore Stock Settings）
5. R 側に最新の UF2 を書き込んだか
6. 切り分けのため `CONFIG_PMW3610_AUTOMOUSE_TIMEOUT_MS=1500` にして試す

### J を押すと左クリックではなく `j` が入力される

```text
A. どこかのキーで &mo 4 を押しながら J → 左クリックになる
   → MOUSE レイヤー自体は正しい。Auto Mouse 側（&trackball の設定 / timeout）を疑う

B. &mo 4 を押しながら J でも j が入力される
   → Layer 4 のキーマップ設定、またはレイヤー番号のずれを疑う
```

### Mod-Tap / Layer-Tap の誤爆が多い

- 長押しのつもりがタップになる → `tapping-term-ms` を短くする、`flavor = "hold-preferred"` を試す
- タップのつもりが長押しになる → `tapping-term-ms` を長くする、`require-prior-idle-ms` を設定する
- 同じキーの連打がリピートしない → `quick-tap-ms = <150>;` のように設定する

### ビルドが失敗する

- Actions のログ末尾に出るエラー行番号を `roBa.keymap` で確認する
- 各レイヤーの `bindings` のキー数が 43 個になっているか（多くても少なくても失敗する）
- Combo の `key-positions` が 0〜42 の範囲か
- カスタム Behavior 名や Macro 名のタイプミスがないか

### 左右がつながらない / PC とペアリングできない

[9.4 節](#94-settings_reset-は通常使わない) の手順で `settings_reset` を左右両方に書き込み、通常ファームウェアを書き直してから再ペアリングします。

---

## 13. チートシート

| やりたいこと | 手順 |
|---|---|
| キーを変える | Keymap Editor → Save → Actions → R 側 UF2 |
| Auto Mouse timeout / CPI を変える | `roBa_R.conf` → commit → Actions → R / L 両方の UF2 |
| Combo / Macro を足す | `roBa.keymap` を手書き → commit → Actions → R 側 UF2 |
| `.keymap` 更新が反映されない | ZMK Studio → Restore Stock Settings |
| 書き込みモードに入る | リセット 2 回押し、または `&bootloader` キー |
| 安定版を保存 | `git tag -a v1.0 -m "stable keymap" && git push origin v1.0` |
| 公式更新を確認 | `git fetch upstream && git log --oneline main..upstream/main` |
| キーマップ図を更新 | Actions → Draw Keymap → Run workflow |
| 別の roBa に移植 | 安定版 UF2 を R / L に書き込み → 再ペアリング |

---

## 14. 参考資料

- roBa 公式リポジトリ: https://github.com/kumamuk-git/roBa
- roBa v3 ビルドガイド: https://github.com/kumamuk-git/roBa/blob/main/doc/v3/buildguide_v3.md
- roBa 公式 ZMK config: https://github.com/kumamuk-git/zmk-config-roBa
- PMW3610 ドライバ（roBa 用フォーク）: https://github.com/kumamuk-git/zmk-pmw3610-driver
- Keymap Editor: https://nickcoutsos.github.io/keymap-editor/
- ZMK Studio: https://zmk.studio/ ・ https://zmk.dev/docs/features/studio
- ZMK: Keymaps & Behaviors: https://zmk.dev/docs/keymaps
- ZMK: キーコード一覧: https://zmk.dev/docs/keymaps/list-of-keycodes
- ZMK: Hold-Tap（Mod-Tap / Layer-Tap の詳細）: https://zmk.dev/docs/keymaps/behaviors/hold-tap
- ZMK: Combos: https://zmk.dev/docs/keymaps/combos
- ZMK: Macros: https://zmk.dev/docs/keymaps/behaviors/macros
- ZMK: Mouse / Pointing: https://zmk.dev/docs/keymaps/behaviors/mouse-emulation
- ZMK: Configuration Overview: https://zmk.dev/docs/config
- keymap-drawer: https://github.com/caksoylar/keymap-drawer
