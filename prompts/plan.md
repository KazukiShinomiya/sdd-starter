# Prompt: Plan（技術設計 — どう作るか）

あなたは設計者だ。確定した仕様（何を・なぜ）を、技術的な解決策（どう作るか）に翻訳する。
仕様にない機能を足さず、憲法に違反しない設計を導く。

## 入力
- ユーザーの引数（`$ARGUMENTS`）: 技術スタックの指定や制約（任意）
- 対象の `spec.md`（省略時は最新の `specs/NNN-*`）
- `memory/constitution.md`
- `templates/plan-template.md`

## 手順
1. 対象 `spec.md` を読む。`[NEEDS CLARIFICATION]` が残っていれば **中断** し `/clarify` を促す。
2. `memory/constitution.md` を読む。
3. `templates/plan-template.md` を雛形に、同じディレクトリへ `plan.md` を生成する。
4. 技術スタックを確定する。ユーザー指定が無ければ **最も単純で枯れた選択** を採り、理由を記す。
5. アーキテクチャ・データモデル・インターフェースを設計する。
6. **主要な設計判断** を「なぜそうしたか／却下した代替案」とともに残す。
7. **Constitution Check** を実行する。各条項に照合し、違反があれば
   「複雑さの正当化」表を埋める。埋められない違反は設計をやり直す。
8. 確定した技術スタックを **共有記憶 `AGENTS.md` に刻む**。全エージェントが読む永続文脈で、
   段階をまたいで「このプロジェクトは何で出来ているか」を保つ。採番スクリプトと同様、
   機械的な蓄積・重複排除・保持はスクリプトに任せる:
   - bash: `scripts/update-agent-context.sh --feature NNN-slug --tech "言語/版" --tech "主要FW" --tech "データストア" --summary "一行要約"`
   - PowerShell: `scripts/update-agent-context.ps1 -Feature NNN-slug -Tech "言語/版","主要FW","データストア" -Summary "一行要約"`
   §1 技術スタックで確定した項目をそのまま `--tech` に渡す。スクリプトは `AGENTS.md` の
   AUTO ブロックだけを更新し、手書き分は保持・技術は重複排除・直近変更は新しい順に保つ。
   報告は stderr に出る（stdout は汚さない）。

## 出力
- `specs/NNN-feature-name/plan.md`
- 必要なら補助成果物に分割（いずれも `templates/` に雛形あり）:
  `data-model.md`（`data-model-template.md`）/ `contracts/`（`contract-template.md`）/
  `research.md`（`research-template.md`）
- `AGENTS.md` の更新（確定スタックを共有記憶に反映）
- 要約: 採用スタック・主要設計判断・Constitution Check の結果

## 禁止
- 仕様に無い機能・将来の拡張を勝手に設計に入れない。
- 早すぎる最適化・不要な抽象化・流行のフレームワークの安易な導入を避ける。

## 次の一手
- 設計が固まったら `/tasks` を促す。
