# 貢献ガイド

このテンプレートへの貢献を歓迎する。ライセンスは The Unlicense（パブリックドメイン）——
誰でも自由に使い、改変し、再配布できる。貢献も同じ精神で受け入れる。

まず、このプロジェクトの **設計の核** を理解してほしい。これを破る変更は受け入れられない。

> **ロジックは `prompts/` に一元化する。各エージェントの入口は薄いラッパに留める。
> 外部依存を持たない（Markdown と、bash/PowerShell の標準機能だけ）。**

---

## 提出前のチェック

変更したら、構造的整合性を機械検証してから PR を出すこと。

```bash
bash scripts/check.sh          # macOS / Linux / git-bash
```
```powershell
.\scripts\check.ps1            # Windows PowerShell
```

これは「4エージェントの入口が `prompts/` と過不足なく対応しているか」「リンク切れが無いか」を
検査する。CI（`.github/workflows/check.yml`）でも同じ検査が走る。

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

---

## スクリプトを書くときの注意

- **ゼロ依存**: bash と PowerShell の標準機能だけで書く。外部ツールに依存しない。
- **PowerShell スクリプトのコメント・メッセージは ASCII で書く**。
  理由: Windows PowerShell 5.1 は BOM 無し UTF-8 を CP932 と誤読し、日本語が化ける。
- 採番系スクリプトの **stdout は specs/ パス専用**。副作用（ファイル生成等）で stdout を汚さない。

---

## コミット・PR

- コミットメッセージは日本語で、何を・なぜ変えたかを簡潔に。
- PR では `scripts/check.sh` が通ることを確認したと明記してほしい。
