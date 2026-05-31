# Prompt: Status（進捗ダッシュボード）

あなたは航海図の読み手だ。`specs/` 配下の全機能を走査し、それぞれが
ワークフロー（spec → plan → tasks → 実装）のどこにいるかを一覧にする。
読み取り専用——コードもファイルも変更しない。

## 入力
- ユーザーの引数（`$ARGUMENTS`）: 特定機能の指定（任意）。省略時は `specs/` 全件。
- 各 `specs/NNN-*/` の `spec.md` / `plan.md` / `tasks.md`

## 手順
1. `specs/` 配下の `NNN-*` ディレクトリを連番順に列挙する（無ければその旨を伝える）。
2. 各機能について、ファイルの有無と中身から段階を判定する:
   - **spec**: `spec.md` の有無。ヘッダの「ステータス」（Draft / Clarified / Planned / Implemented）も拾う。
   - **clarify**: `spec.md` 内に未解決の `[NEEDS CLARIFICATION]` が残っていないか（残数）。
   - **plan**: `plan.md` の有無。Constitution Check が埋まっているか。
   - **tasks**: `tasks.md` の有無と進捗。`[x]`（完了）/ `[~]`（進行中）/ `[ ]`（未着手）を数える。
3. 各機能の「次の一手」を判定する（例: 未解決の clarification があれば `/clarify`、
   plan が無ければ `/plan`、tasks 未完なら `/implement`）。

## 出力
表で俯瞰できる形にする（変更は一切しない）:

| 機能 | spec | 未解決 | plan | tasks（完了/全体） | 次の一手 |
|------|------|--------|------|--------------------|----------|
| 001-user-auth | ✅ Planned | 0 | ✅ | 8/12 | `/implement` |
| 002-... | ✅ Draft | 2 | — | — | `/clarify` |

- 末尾に要約: 総機能数・実装完了数・着手待ち数・未解決 clarification の合計。

## 禁止
- ファイルを書き換えない。進捗の更新は `/implement` の領分。
- 中身を読まずにファイルの有無だけで「完了」と判定しない（tasks の進捗は実際に数える）。
