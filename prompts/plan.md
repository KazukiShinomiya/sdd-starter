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

## 出力
- `specs/NNN-feature-name/plan.md`
- 必要なら `data-model.md` / `contracts/` / `research.md` に分割
- 要約: 採用スタック・主要設計判断・Constitution Check の結果

## 禁止
- 仕様に無い機能・将来の拡張を勝手に設計に入れない。
- 早すぎる最適化・不要な抽象化・流行のフレームワークの安易な導入を避ける。

## 次の一手
- 設計が固まったら `/tasks` を促す。
