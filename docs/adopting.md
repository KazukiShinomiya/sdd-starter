# このテンプレで自分のプロダクトを作り始める

このリポジトリは **SDD ワークフローの土台**と、**テンプレ自身を維持するための装置**の
二層でできている。自分のプロダクトを始めるときは、前者を残し、後者を片付ければいい。
この文書はその切り分け手順だ。

> このテンプレは「早すぎる自動化を禁じる」憲法を持つ（`memory/constitution.md` の精神）。
> だから移行も**スクリプトで自動化せず、手順を文書で示す**。やることは多くない。

---

## 0. 始める前に — 退避してから片付ける

ここから先は **削除・上書き**を含む。元に戻せる状態を作ってから進む。

- まだ git 管理下に無いなら `git init` し、まず1コミット残す。
- テンプレの素の状態を後で見返したいなら、タグを打っておく:
  `git tag template-baseline`（いつでも `git show template-baseline:path` で参照できる）。

消す対象はすべて git 履歴に残る。慌てて完全消去する必要はない。

---

## 1. 残すもの（SDD ワークフローの本体）

これらが「依存なしで SDD を回す」道具だ。**触らず残す**:

- `prompts/` — 各コマンドの手順（真実の源）。
- `templates/` — 成果物の雛形（spec / plan / tasks と plan の補助）。
- `scripts/new-feature.{sh,ps1}` / `scripts/update-agent-context.{sh,ps1}` — 採番・分岐・共有文脈更新のヘルパ。
- `.claude/` `.cursor/` `.github/prompts/` `.gemini/` のコマンド入口 — 使うエージェントの分だけ残せばよい。
- `memory/` — 憲法の置き場。
- `specs/` — これから君の機能成果物が溜まる場所。

---

## 2. リセットするもの（中身を自分のものに入れ替える）

ファイルは残し、**中身をプロダクト用に差し替える**:

| 対象 | やること |
|------|----------|
| `memory/constitution.md` | プレースホルダ（`[PROJECT_NAME]` 等）を自分の原則で埋める。`/constitution` でも直接編集でもよい。 |
| `AGENTS.md` | 既にほぼ空。プロダクト名・技術スタックを書き始める起点にする（`/plan` が `AUTO:BEGIN`〜`AUTO:END` を増分更新する）。 |
| `README.md` | テンプレの説明を、**君のプロダクトの README** に差し替える。 |
| `CLAUDE.md` | テンプレ運用指針を、プロダクト固有の指針に差し替える。`@AGENTS.md` の import 行は残してよい。 |

---

## 3. 片付けるもの（テンプレ自身の装置）

ワークフローを回すのに不要な「テンプレを説明・維持する」ファイルだ。**消すか退避する**:

- `examples/` — 学習用の記入済みサンプル3本。読み終えたら消してよい（履歴には残る）。
- `docs/quickstart.md` / `docs/adopting.md` — テンプレの使い方を説く文書（この文書自身も含む）。
- `CONTRIBUTING.md` — **テンプレへの**貢献ガイド。自分のプロダクトの貢献ガイドに置き換えるか消す。

```bash
rm -rf examples docs/quickstart.md docs/adopting.md CONTRIBUTING.md   # bash
```
```powershell
Remove-Item -Recurse -Force examples, docs/quickstart.md, docs/adopting.md, CONTRIBUTING.md   # PowerShell
```

`SESSION_STATE.md` はもともと追跡対象外（`.gitignore` 済み）なので、残っていても push されない。

---

## 4. メタ検査をどうするか（要・判断）

`scripts/check.{sh,ps1}` ・ `scripts/test-parity.{sh,ps1}` ・ `.github/workflows/check.yml` ・
`tests/golden/` は、**テンプレ自身の構造的健全性**を守る道具だ。残すか消すかは使い方で決める:

- **残す**（推奨されるケース）: 自分で**コマンドやエージェント入口を増やす**つもりがあるなら有用だ。
  `check` は入口と `prompts/` の対応・リンク切れ・取り違えを捕まえ続ける。`test-parity` は
  `new-feature` / `update-agent-context` を改造したときの番兵になる。
  - `examples/` を消すと `check` の「examples 鮮度ゲート」は対象ゼロで素通りする（無害）。
    気になるなら該当ブロックだけ削ってよい。
- **消す**: ワークフローを**そのまま使い、入口もヘルパも改造しない**なら、メタ検査は不要だ。
  `scripts/check.*` ・ `scripts/test-parity.*` ・ `.github/workflows/check.yml` ・ `tests/` を消す。

---

## 5. 仕上げの確認

- プレースホルダの消し残しを掃除する:
  ```bash
  grep -rn "PROJECT_NAME" .            # bash — 何も出なければよい
  ```
  ```powershell
  Get-ChildItem -Recurse -File | Select-String "PROJECT_NAME"   # PowerShell
  ```
- 最初の機能を流す。手順は元の [クイックスタート](./quickstart.md) と同じだ
  （消した場合は記憶の通りに）:

  ```
  /constitution     # 自分の原則を確立
  /specify  ...      # 最初の機能の「何を・なぜ」
  /plan ... → /tasks → /implement
  ```

ここから先は、もうテンプレではなく**君のプロダクト**だ。
