# クイックスタート — 最初の30分

このテンプレートで、最初の機能を「憲法 → 仕様 → 設計 → タスク → 実装」まで通す手順。
ここでは Claude Code の slash command で書くが、他エージェントでも入口は同じだ
（[README の対応表](../README.md#その他のエージェント)を参照）。

迷ったら、完成済みの実例を読むのが早い:
- `examples/url-shortener/` — Web API + DB のフル工程（補助成果物 research/data-model/contracts つき）
- `examples/toc-generator/` — 小さな CLI の最短経路（spec → plan → tasks のみ）

---

## 0. 前提

AIエージェント（Claude Code / Cursor / GitHub Copilot / Gemini CLI など）が
このリポジトリを開いていること。それだけだ。インストールも依存もない。

## 1. 憲法を定める（一度だけ）

```
/constitution
```

プロジェクトが守る不可侵の原則（単純さ優先・テスト駆動など）を `memory/constitution.md` に確立する。
書き方に迷ったら `examples/url-shortener/constitution.md`（記入済みの実例）を見るとよい。
以降の全段階が、この憲法を上位制約として導かれる。

## 2. 仕様を書く（何を・なぜ）

```
/specify  ユーザーがログインできる認証機能を追加したい
```

`specs/NNN-feature-name/spec.md` が作られる（採番スクリプトが連番と雛形を用意する）。
**技術の話は書かない**。何を・なぜ、と受け入れ基準（テストに変換できる条件）だけを書く。

## 3. 曖昧さを潰す（必要なら）

```
/clarify
```

`[NEEDS CLARIFICATION]` や隠れた曖昧さを、1問ずつの質問で確定させる。
小さく明白な機能なら飛ばしてよい。

## 4. 設計する（どう作るか）

```
/plan  Python と FastAPI で
```

`plan.md` が作られる。技術スタックを確定し、憲法に違反しないか照合する（Constitution Check）。
設計が大きければ `research.md` / `data-model.md` / `contracts/` に切り出す
（`templates/` に雛形あり。url-shortener の例を参照）。

## 5. タスクに分解する

```
/tasks
```

`tasks.md` に、完了の定義つきの実装タスクが並ぶ。全受け入れ基準がいずれかのタスクで
カバーされること（トレーサビリティ）を確認する。

## 6. 検証する（任意だが推奨）

```
/analyze      # spec/plan/tasks が互いに矛盾しないか横断検証
/checklist plan   # 単一成果物の内部品質を観点表で検査
```

## 7. 実装する

```
/implement
```

タスクを依存順に一つずつ。憲法が TDD を定めるなら、失敗するテストを先に書く。
完了の定義を満たしたタスクだけ `[x]` になる。

---

## その後

- **仕様が変わったら**: `/amend  001-... SSO も対象に含める` — 変更を履歴に残し、
  plan/tasks への波及を報告する（黙って書き換えない）。
- **進捗を俯瞰**: `/status` — どの機能が spec/plan/tasks/実装のどこにいるか一覧で見える。
- **課題化**: `/taskstoissues` — tasks をトラッカー用の issue ドラフトに変換。

すべての手順の本体は `prompts/*.md` にある。エージェントを問わず、同じ手順が再現される。
