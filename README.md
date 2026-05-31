# Spec Kit Home — 仕様駆動開発テンプレート

AIエージェントと共に **Spec-Driven Development（仕様駆動開発, SDD）** を実践するための、
ゼロ依存・言語非依存・複数エージェント対応のプロジェクトテンプレート。

GitHub [Spec Kit](https://github.com/github/spec-kit) が確立した型を借りつつ、
Python製CLIなどの外部依存を一切持たず、**Markdown だけで完結**するよう再構成している。

---

## なぜ仕様駆動開発なのか

AIエージェントにいきなり「作って」と頼むと、暗黙の前提のまま実装に突っ込み、
意図とずれたコードが量産される。仕様駆動開発はその逆を行く。

> **「何を」「なぜ」を先に固め、設計を導き、最後に実装する。**

各段階が検証可能な Markdown 成果物を残し、それが次段階の入力になる。
人間はコードではなく**仕様と設計のレビュー**に集中でき、AIの暴走を構造的に防ぐ。

---

## ワークフロー

```
①constitution ──> ②specify ──> [③clarify] ──> ④plan ──> ⑤tasks ──> ⑥implement
   不可侵の原則      何を/なぜ     曖昧さ解消      技術設計    タスク分解   実装
                        └──────────── [analyze: 整合性検証] ───────────┘
```

| 段階 | コマンド | 成果物 | 問い |
|------|----------|--------|------|
| ① 憲法 | `/constitution` | `memory/constitution.md` | この製品が守るべき不可侵の原則は何か |
| ② 仕様 | `/specify` | `specs/NNN-*/spec.md` | **何を**作るか・**なぜ**作るか |
| ③ 明確化 | `/clarify` | spec.md 更新 | 曖昧な点・未決定事項は何か |
| ④ 設計 | `/plan` | `specs/NNN-*/plan.md` | **どう**作るか（技術選定・構造） |
| ⑤ タスク | `/tasks` | `specs/NNN-*/tasks.md` | 実装可能な単位への分解 |
| 検証 | `/analyze` | レポート | 仕様・設計・タスクは整合しているか |
| ⑥ 実装 | `/implement` | コード | タスクを順に実行 |

`[]` 内は任意。小さな機能なら飛ばしてよい。

---

## ディレクトリ構造

```
speckit-home/
├── README.md                  # この道標
├── memory/
│   └── constitution.md        # プロジェクトの不可侵原則（全段階の上位制約）
├── templates/                 # 各成果物の雛形（言語非依存）
│   ├── spec-template.md
│   ├── plan-template.md
│   └── tasks-template.md
├── prompts/                   # ★ロジックの本体（エージェント非依存）
│   ├── constitution.md
│   ├── specify.md
│   ├── clarify.md
│   ├── plan.md
│   ├── tasks.md
│   ├── analyze.md
│   └── implement.md
├── scripts/                   # 採番ヘルパ（bash + PowerShell 両対応・ゼロ依存）
│   ├── new-feature.sh         #   次の連番で specs/NNN-name/ を作りパスを返す
│   └── new-feature.ps1
├── specs/                     # 機能ごとの成果物がここに溜まる
│   └── NNN-feature-name/
│       ├── spec.md
│       ├── plan.md
│       └── tasks.md
├── examples/                  # 動作例（ドッグフード）
│   └── url-shortener/         #   spec/plan/tasks の一気通貫サンプル
├── .claude/commands/          # Claude Code用の入口（薄いラッパ）
├── .cursor/commands/          # Cursor用の入口
├── .github/prompts/           # GitHub Copilot用の入口
└── .gemini/commands/          # Gemini CLI用の入口
```

**設計の核**: ロジックは `prompts/` に一元化されている。
各エージェント用の入口（`.claude/commands/` など）は、対応する `prompts/*.md` を読んで
実行するだけの薄いラッパだ。新しいエージェントへの対応は「入口を足す」だけで済む。

---

## 使い方

### Claude Code（slash command が使える）

```
/constitution   # 最初に一度。プロジェクトの原則を確立
/specify        ユーザーがログインできる認証機能を追加したい
/clarify        # 必要なら曖昧さを潰す
/plan           # 技術スタックを指定して設計
/tasks          # タスクに分解
/implement      # 実装を実行
```

### その他のエージェント

主要エージェント向けの入口を同梱済み。どれも中身は `prompts/*.md` を参照する薄いラッパだ。

| エージェント | 入口の場所 | 形式 | 引数記法 |
|--------------|-----------|------|----------|
| Claude Code | `.claude/commands/*.md` | frontmatter + 本文 | `$ARGUMENTS` |
| Cursor | `.cursor/commands/*.md` | プレーン Markdown | コマンドに続けて記述 |
| GitHub Copilot | `.github/prompts/*.prompt.md` | frontmatter + 本文 | `${input:...}` |
| Gemini CLI | `.gemini/commands/*.toml` | TOML | `{{args}}` |

入口の無いツールでも、`prompts/*.md` をそのまま渡せば同じ手順を再現できる。

```
prompts/specify.md の手順に従って、次の要件の仕様書を作成して:
「ユーザーがログインできる認証機能」
```

`prompts/` がエージェント非依存の真実の源なので、どのツールでも結果は揃う。

---

## 新しいエージェントへの対応を足すには

1. そのエージェントのコマンド形式のファイルを作る（例: `.cursor/commands/specify.md`）
2. 中身は「`prompts/specify.md` の手順に従って `$ARGUMENTS` を処理せよ」とするだけ

ロジックを二重に書かない。これがこのテンプレートの美学だ。
