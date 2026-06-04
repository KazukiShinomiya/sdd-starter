# 貢献ガイド

このテンプレートへの貢献を歓迎する。ライセンスは The Unlicense（パブリックドメイン）——
誰でも自由に使い、改変し、再配布できる。貢献も同じ精神で受け入れる。

まず、このプロジェクトの **設計の核** を理解してほしい。これを破る変更は受け入れられない。

> **ロジックは `prompts/` に一元化する。各エージェントの入口は薄いラッパに留める。
> 外部依存を持たない（Markdown と、bash/PowerShell の標準機能だけ）。**

---

## 提出前のチェック

変更したら、PR を出す前に **2種の機械検証**を両系統（bash / PowerShell）で走らせること。

```bash
bash scripts/check.sh          # 構造の検査
bash scripts/test-parity.sh    # 振る舞いの等価性（golden 比較）
```
```powershell
.\scripts\check.ps1            # 構造の検査（Windows PowerShell）
.\scripts\test-parity.ps1      # 振る舞いの等価性（Windows PowerShell）
```

- **`check`** … 4エージェントの入口が `prompts/` と過不足なく対応しているか、リンク切れが無いか、
  各 `prompts/*.md` が必須4節（入力/手順/出力/禁止）を備えるかを検査する。
- **`test-parity`** … `new-feature` と `update-agent-context` の bash 版と PowerShell 版が
  **同じ入力に同じ出力**を返すか（slug 正規化・採番、`AGENTS.md` 生成）を golden と byte 比較で検証する。
  片方だけ直して片方を忘れる乖離を捕まえるための番兵だ。

CI（`.github/workflows/check.yml`）は ubuntu と Windows PowerShell 5.1 の**両方**でこの2種を走らせる。

---

## コマンドを追加する

ロジックを二重に書かないこと。手順は2段階だ。

1. **真実の源を書く**: `prompts/<command>.md` に手順を書く。
   既存の prompt（`入力 / 手順 / 出力 / 禁止 / 次の一手` の構成）に倣う。
2. **4エージェントの入口を足す**（中身は `prompts/<command>.md` を読んで実行せよ、と書くだけ）:
   - `.claude/commands/<command>.md` — frontmatter + `$ARGUMENTS`
   - `.cursor/commands/<command>.md` — プレーン Markdown（引数はコマンドに続けて記述）
   - `.github/prompts/<command>.prompt.md` — frontmatter（`mode: agent`）+ `${input:...}`
   - `.gemini/commands/<command>.toml` — TOML（`{{args}}`）

`scripts/check.sh` は、いずれかの入口を足し忘れると失敗する。これが二重化と取りこぼしを防ぐ。

## 新しいエージェントへの対応を足す

そのエージェントのコマンド形式で、全 `prompts/*.md` に対応する入口ファイルを作るだけ。
中身は対応する `prompts/*.md` を参照する薄いラッパにする。

## 補助テンプレートを足す

`templates/*-template.md` を追加し、対応する `prompts/*.md` から参照する。
参照名は `*-template.md` 形式にすること（`check` がリンク切れを検査する）。

> **テンプレを持つコマンド・持たないコマンド**: `templates/` を持つのは、成果物が
> **固定構造で雛形化できる**もの（spec / plan / tasks と plan の補助 3種）だけだ。
> `checklist` / `status` / `analyze` などは、入力に応じて**構造そのものを動的に組み立てる**
> 成果物なので、意図的に固定テンプレを持たない。コマンドごとに template が要るわけではない
> ——「雛形にできる形か」で判断する。

---

## スクリプトを書くときの注意

- **ゼロ依存**: bash と PowerShell の標準機能だけで書く。外部ツールに依存しない。
- **PowerShell スクリプトのコメント・メッセージは ASCII で書く**。
  理由: Windows PowerShell 5.1 は BOM 無し UTF-8 を CP932 と誤読し、日本語が化ける。
  - 例外: スクリプト内にどうしても日本語リテラルが要る場合（`check.ps1` は prompts の日本語節名を、
    `test-parity.ps1` は日本語の slug を照合する）は、そのファイルを **UTF-8 BOM 付き**で保存する。
    BOM があれば 5.1 も誤読しない。検査対象ファイルは
    `[System.IO.File]::ReadAllText($p, [Text.Encoding]::UTF8)` で明示的に読むこと。
- 採番系スクリプトの **stdout は specs/ パス専用**。副作用（ファイル生成等）で stdout を汚さない。

### パリティテストと golden

`new-feature` か `update-agent-context` の**振る舞いを意図的に変えた**ときは、`tests/golden/` の
期待値も更新する。golden は手書きせず、bash 版の実出力から再生成する（隔離した temp で実行する）:

1. `update-agent-context.sh` を temp で走らせて出力を得る。
2. 生成物を目視で確認してから `tests/golden/agents-*.md` に上書きする。
3. `bash scripts/test-parity.sh` と `.\scripts\test-parity.ps1` の**両方**が緑になることを確認する。
   両系統が同一 golden を byte 一致で通ってはじめて、振る舞いが等価だと言える。

golden・fixture は **LF・BOM 無し UTF-8** で保つこと（`update-agent-context` の出力形式に一致させる）。

---

## コミット・PR

- コミットメッセージは日本語で、何を・なぜ変えたかを簡潔に。
- PR では `check` と `test-parity` が両系統で通ることを確認したと明記してほしい。

---

## 本家 Spec Kit との追従方針

このテンプレートは GitHub [Spec Kit](https://github.com/github/spec-kit) が確立した
ワークフローの「型」を借りている。本家が型を更新したとき**どこまで追うか**の方針を明示しておく
（場当たりな判断で揺れないために）:

- **追う**: 段階構成・成果物の考え方・各段階の「問い」の磨き込みなど、**思想レベル**の更新。
  本テンプレートの三本柱（日本語ネイティブ / ゼロ依存・Markdown だけ / 学習用サンプル）を
  強める方向なら積極的に取り込む。
- **追わない**: `specify` CLI（Python）への依存を前提とする機能、多数エージェントの網羅、
  本家固有のディレクトリ規約など、**ゼロ依存・少数精鋭の設計と衝突するもの**。
- **迷ったら**: 「真実の源は `prompts/` に一元化」「入口は薄いラッパ」「外部依存を増やさない」
  の3原則に照らす。これを破るなら追従しない。
- 追従する場合も、まず `prompts/*.md`（真実の源）を更新し、入口・テンプレ・サンプルを揃え、
  `check` と `test-parity` を通してから PR にする。
