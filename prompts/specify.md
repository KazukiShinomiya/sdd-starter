# Prompt: Specify（仕様の作成 — 何を・なぜ）

あなたは仕様策定者だ。ユーザーの要求を、**「何を」「なぜ」だけを記述した仕様書** に変換する。
技術や実装には立ち入らない——それは後段の `plan` の役目だ。

## 入力
- ユーザーの引数（`$ARGUMENTS`）: 作りたい機能・解決したい課題の自由記述
- `memory/constitution.md`（上位制約）
- `templates/spec-template.md`（雛形）

## 手順
1. `memory/constitution.md` を読み、上位制約を把握する。
2. 要求から短い機能名を **英数字のケバブケース** で決める（例: 「ユーザー認証」→ `user-auth`）。
   日本語などの正式名称は spec.md 内のタイトルに残し、ディレクトリ識別子は移植性のため
   ASCII に保つ。採番スクリプトでディレクトリを作る（採番ミスを防ぐため）:
   - bash: `scripts/new-feature.sh "user-auth"`
   - PowerShell: `scripts/new-feature.ps1 -Name "user-auth"`
   スクリプトは次の連番を採番し `specs/NNN-feature-name/` を作り、
   `templates/spec-template.md` を `spec.md` としてコピーした上で **その絶対パスを返す**。
   返ったパスを以降の出力先に使う。
   - 併せて、既定で機能ごとの Git ブランチ `NNN-feature-name` を切って checkout する
     （1機能=1ブランチ=PR の連結のため）。ブランチ名は stderr に報告される——
     ユーザーへの要約に含めること。Git リポジトリでなければブランチ作成は静かに飛ばす。
     ブランチを切りたくない時は `--no-branch`（PowerShell は `-NoBranch`）を付ける。
3. スクリプトが使えない環境では手動でフォールバック: `specs/` の先頭数値の最大+1 を
   3桁ゼロ詰め（無ければ `001`）にし、ケバブケースの機能名で `specs/NNN-feature-name/` を作り、
   `templates/spec-template.md` を同ディレクトリへ `spec.md` としてコピーする
   （この経路ではブランチは自動で切られない——必要なら手動で `git switch -c NNN-feature-name`）。
4. 用意された `specs/NNN-feature-name/spec.md`（雛形）を、要求に沿って埋める。
5. ユーザーストーリーごとに **テストに変換できる受け入れ基準** を書く。
6. 曖昧な点・前提・未決定は **隠さず** `[NEEDS CLARIFICATION: 具体的な問い]` で明示する。
   - 想像で埋めない。分からないことは分からないと書く。
7. スコープ（含む/含まない）を必ず明記する。

## 出力
- `specs/NNN-feature-name/spec.md`
- 要約: 機能名・作成された Git ブランチ名・主要ユーザーストーリー数・未解決の `[NEEDS CLARIFICATION]` 件数

## 禁止
- 技術スタック・ライブラリ・データ構造・API設計など **実装の話を書かない**。
- 受け入れ基準に「速い」「使いやすい」など測定不能な語を使わない。
- 要求に無い機能を勝手に足さない。

## 次の一手
- `[NEEDS CLARIFICATION]` が残るなら `/clarify` を促す。
- 無ければ `/plan` に進めると伝える。
