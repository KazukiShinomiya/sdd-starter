# CLAUDE.md

Claude Code がこのリポジトリで作業するときの文脈。これは仕様駆動開発（SDD）テンプレートだ。
このファイルは **Claude 固有の運用指針** に絞る。エージェント非依存の文脈は `AGENTS.md`、
ロジックの本体は `prompts/*.md` にある（下記）。

> このテンプレートを使って自分のプロダクトを作る場合は、このファイルを差し替えてよい。
> ここに書くのは「SDD テンプレートとして作業する」ための指針であって、下流プロダクトの
> ルールではない。移行の全体手順は [`docs/adopting.md`](./docs/adopting.md) を参照。

## 共有文脈（全エージェント共通）

@AGENTS.md

`AGENTS.md` が技術スタックと最近の変更を蓄積する永続文脈だ（`AUTO:BEGIN`〜`AUTO:END` は
`/plan` が機械更新する）。Cursor / Copilot / Gemini も同じ `AGENTS.md` を読む。

## このプロジェクトの核（変更時に守る）

- **真実の源は `prompts/*.md`**。各エージェントの入口（`.claude/commands/` 等）は、対応する
  prompt を読むだけの薄いラッパだ。ロジックを二重に書かない。
- **ワークフロー**: `constitution` → `specify` →〔`clarify`〕→ `plan` → `tasks` →〔`analyze`〕→
  `implement`。各段階は検証可能な Markdown 成果物を残し、次段階の入力になる。人間に断りなく
  段階を飛ばして先へ進めない。
- **1機能 = 1ブランチ = 1 PR**。`scripts/new-feature.{sh,ps1}` が次の連番で `specs/NNN-*/` を作り、
  機能ブランチを切る。
- **品質ゲートは両肺主義**。検査ロジックは bash と PowerShell に同じものを刻み、CI で両 OS を回す。
  構造に触れる変更の前後で `bash scripts/check.sh`（Windows は `.\scripts\check.ps1`）を通す。

## Claude 固有の運用指針

- **サブエージェント委譲**: 重い `/analyze`・`/implement` で対象が大きいときは、コンテキスト保全と
  独立検証のためサブエージェントに委譲してよい。ただし **`spec.md` / `plan.md` / `tasks.md`
  （真実の源）への書き込みは親が一元管理する**。サブエージェントには読み取り・分析・限定的な実装を
  任せ、成果物への最終統合は親が担う。これにより複数の書き手が真実の源を奪い合う事態を防ぐ。
- **prompts/ はエージェント非依存に保つ**。サブエージェント等の Claude 固有概念を `prompts/*.md` に
  書かない。それらはこの `CLAUDE.md` に留め、`prompts/` はどのエージェントでも同じ結果を出す
  真実の源であり続ける。
