# SDD Starter — 仕様駆動開発テンプレート

[![check](https://github.com/KazukiShinomiya/sdd-starter/actions/workflows/check.yml/badge.svg)](https://github.com/KazukiShinomiya/sdd-starter/actions/workflows/check.yml)

AIエージェントと共に **Spec-Driven Development（仕様駆動開発, SDD）** を実践するための、
ゼロ依存・言語非依存・複数エージェント対応のプロジェクトテンプレート。

GitHub [Spec Kit](https://github.com/github/spec-kit) が確立した型を借りつつ、
Python製CLIなどの外部依存を一切持たず、**Markdown だけで完結**するよう再構成している。

> 🚀 すぐ始めるなら [**クイックスタート（最初の30分）**](./docs/quickstart.md) へ。

---

## なぜ本家 Spec Kit ではなく、これなのか

本家 [Spec Kit](https://github.com/github/spec-kit) は優れた公式ツールだ。30以上のエージェントに
対応し、Python製の `specify` CLI でプロジェクトを生成する。**汎用性とエコシステムでは本家に分がある。**
このテンプレートは、そこと正面から競うものではない。

代わりに、本家が手薄な三点に絞って尖らせている:

- **日本語ネイティブ** — 全工程・全プロンプト・全解説が日本語。英語圏向けの本家に対し、
  日本語で SDD を学び・実践したい層のための道具だ。
- **ゼロ依存・Markdown だけ** — Python も CLI も要らない。clone すれば即動く。
  外部ツールを増やしたくない人向け。
- **学習用の一気通貫サンプル** — `examples/` に憲法から実装直前まで記入済みの実例を3本
  （Web API のフル工程 / CLI の最短経路 / **曖昧さに躓き仕様が変わる messy な工程**）。
  本家が見せない「完成形」と「現実の躓き」の両方を読んで学べる。

「より高機能な spec-kit」ではない。**「日本語で、依存なしで、サンプルから学べる」SDD テンプレート**
——それがこの道具の存在理由だ。

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

### 補助コマンド（任意）

| コマンド | 成果物 | 使いどき |
|----------|--------|----------|
| `/checklist` | `specs/NNN-*/checklists/*.md` | 1つの成果物（spec/plan/tasks）の**内部品質**を観点表で検査する。`/analyze` が成果物**間**の整合を見るのに対し、こちらは単体の質を問う。 |
| `/taskstoissues` | `specs/NNN-*/issues.md` | `tasks.md` を課題トラッカー用の issue ドラフトに変換する。既定はゼロ依存の Markdown 出力。`gh` があれば任意で GitHub issue 化。 |
| `/status` | レポート | `specs/` 全体を走査し、各機能が spec/plan/tasks/実装のどこにいるかを一覧化する進捗ダッシュボード。読み取り専用。 |
| `/amend` | spec.md 更新 | 確定済みの仕様を改訂し、**変更履歴**と下流（plan/tasks）への波及を記録する。仕様変更を黙って入れず、明示的に追跡する。 |

---

## ディレクトリ構造

```
sdd-starter/
├── README.md                  # この道標
├── LICENSE                    # The Unlicense（パブリックドメイン）
├── CONTRIBUTING.md            # 貢献ガイド（コマンド追加手順・設計の核）
├── CLAUDE.md                  # Claude Code 固有の運用指針（@AGENTS.md を import・差し替え可）
├── AGENTS.md                  # 全エージェント共有の永続文脈（/plan が技術スタックを増分更新）
├── docs/
│   ├── quickstart.md          # クイックスタート（最初の30分）
│   └── adopting.md            # このテンプレで自分の製品を作り始める手順
├── memory/
│   └── constitution.md        # プロジェクトの不可侵原則（全段階の上位制約）
├── templates/                 # 各成果物の雛形（言語非依存）
│   ├── spec-template.md
│   ├── plan-template.md
│   ├── tasks-template.md
│   ├── research-template.md    #   plan の補助: 技術選定の下調べ
│   ├── data-model-template.md  #   plan の補助: §3 データモデルの詳細
│   └── contract-template.md    #   plan の補助: §4 インターフェース契約
├── prompts/                   # ★ロジックの本体（エージェント非依存）
│   ├── constitution.md
│   ├── specify.md
│   ├── clarify.md
│   ├── plan.md
│   ├── tasks.md
│   ├── analyze.md
│   ├── implement.md
│   ├── checklist.md            #   補助: 成果物の内部品質チェック
│   ├── taskstoissues.md        #   補助: タスクの課題化
│   ├── status.md               #   補助: 進捗ダッシュボード
│   └── amend.md                #   補助: 仕様変更の追跡
├── scripts/                   # ヘルパ（bash + PowerShell 両対応・ゼロ依存）
│   ├── new-feature.sh         #   次の連番で specs/NNN-name/ を作り、機能ブランチを切る
│   ├── new-feature.ps1
│   ├── update-agent-context.sh #  AGENTS.md に技術スタックを増分蓄積（/plan が呼ぶ）
│   ├── update-agent-context.ps1
│   ├── check.sh               #   構造的整合性の検査（CI でも実行）
│   └── check.ps1
├── specs/                     # 機能ごとの成果物がここに溜まる
│   └── NNN-feature-name/
│       ├── spec.md
│       ├── plan.md
│       └── tasks.md
├── examples/                  # 動作例（ドッグフード）
│   ├── url-shortener/         #   Web API + DB のフル工程（constitution〜tasks + 補助成果物）
│   ├── toc-generator/         #   小さな CLI の最短経路（spec → plan → tasks）
│   └── library-loan/          #   messy な現実: constitution〜tasks。/clarify で曖昧さを潰し /amend で仕様変更が走る工程
├── .github/workflows/         # CI（テンプレの構造的整合性を自動検査）
├── .claude/commands/          # Claude Code用の入口（薄いラッパ）
├── .cursor/commands/          # Cursor用の入口
├── .github/prompts/           # GitHub Copilot用の入口
└── .gemini/commands/          # Gemini CLI用の入口
```

**設計の核**: ロジックは `prompts/` に一元化されている。
各エージェント用の入口（`.claude/commands/` など）は、対応する `prompts/*.md` を読んで
実行するだけの薄いラッパだ。新しいエージェントへの対応は「入口を足す」だけで済む。

---

## エージェント共有メモリ（AGENTS.md）

`/specify` は機能ごとに **Git ブランチ `NNN-feature-name`** を切る（1機能=1ブランチ=PR）。
`/plan` は確定した技術スタックを **`AGENTS.md`** に増分で刻む——全エージェント
（Claude / Cursor / Copilot / Gemini ほか）が読む永続文脈だ。これにより、段階や
セッションをまたいでも AI は「このプロジェクトが何で出来ているか」を保ち続ける。

- 機械管理されるのは `AGENTS.md` の `AUTO:BEGIN`〜`AUTO:END` ブロックのみ。
  **その外側に書いた手書きの約束事は、更新しても保持される。**
- 技術スタックは重複排除して蓄積し、直近の変更は新しい順に保つ。
- 更新は `scripts/update-agent-context.{sh,ps1}` が担う（`/plan` が自動で呼ぶ）。
- ブランチを切りたくない時は `scripts/new-feature.sh --no-branch`（PowerShell は `-NoBranch`）。
  Git リポジトリでなければブランチ作成は静かに飛ばす。

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

任意の補助コマンドは、どの段階でも差し込める:

```
/checklist plan   # 直近の plan.md の内部品質を観点表で検査
/status           # specs/ 全体の進捗（どの機能がどの段階か）を俯瞰
/taskstoissues    # tasks.md を課題トラッカー用の issue ドラフトに変換
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

---

## 整合性の検査

入口とロジック（`prompts/`）の対応・リンク切れを機械検証できる。

```bash
bash scripts/check.sh          # macOS / Linux / git-bash
```
```powershell
.\scripts\check.ps1            # Windows PowerShell
```

同じ検査が CI（`.github/workflows/check.yml`）でも走り、テンプレの構造的整合を守る。

---

## 自分の製品に使う

このテンプレで自分のプロダクトを作り始めるなら、SDD ワークフローの本体を残し、
テンプレ自身の装置（examples・メタ検査・説明文書）を片付ける。残す/リセット/片付けるの
切り分け手順は [**採用ガイド（docs/adopting.md）**](./docs/adopting.md) にまとめてある。

---

## 貢献

コマンド追加やエージェント対応の手順は [CONTRIBUTING.md](./CONTRIBUTING.md) を参照。
ロジックは `prompts/` に一元化し、入口は薄いラッパに留める——この核を守る限り歓迎する。

## ライセンス

[The Unlicense](./LICENSE)（パブリックドメイン）。誰でも自由に使い、改変し、再配布できる。
帰属表示も不要だ。
