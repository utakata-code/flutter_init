---
name: utakata-migration
description: utakata 導入前からある既存プロジェクトを utakata 対応にする。doc/ の名前が衝突している、AI/ ディレクトリが残っている、utakata.yaml がまだ無いプロジェクトを、既存の資料を失わずに移行するときに使う。
---

# 既存プロジェクトの utakata 移行

utakata を前提にせず育ったプロジェクトを、**資料を1つも失わずに**移行する。

大工事になる。専用ブランチで、段階ごとにコミットしながら進める。

## 最初に確認すること

**ユーザーの確認なしに始めない。** この作業はディレクトリを動かす。

```bash
git status                 # 未コミットの変更が無いこと
git switch -c chore/utakata-migration
utakata --version          # 1.7.1 以降であること
```

未コミットの変更が残っているなら、**先にコミットしてもらう**。移行の途中で
「元が何だったか」を git で辿れなくなるのが一番まずい。

## utakata が `doc/` 配下で使う名前

ここに挙げた名前は utakata が読み書きする。**同名の既存ディレクトリがあると
中身が混ざる。**

| パス | 用途 |
|---|---|
| `doc/specs/plan.yaml` | 機能計画(マスター) |
| `doc/records/` | ログ・合意・原文・セッション(追記のみ) |
| `doc/impl/` | 実装計画。レーンごとのサブディレクトリを持つ |
| `doc/preview/` | 生成物。手で書かない |
| `doc/knowledge/` | 案件固有のナレッジ |
| `doc/archive/` | 凍結した資料 |
| `doc/summary.md` | 案件サマリー |

**これ以外の名前は衝突しない。** `doc/report/` `doc/legal/` `doc/store/`
`doc/handover/` などはそのまま残してよい。動かす必要はない。

紛らわしい例外が1つある。**`doc/spec`(単数)は衝突しない**が、utakata は
`doc/specs`(複数)を使うので、両方あると人が混乱する。統合するかは
ユーザーに聞く。**勝手に統合しない。**

## 手順

### Step 0. 棚卸し

何があるかを先に記録する。移行後に「これはどこへ行った」と聞かれたときに
答えられるようにするため。

```bash
ls doc/ AI/ .claude/ 2>/dev/null
find doc -type f | wc -l
```

衝突するものを名指しで確認する:

```bash
for d in specs records preview impl knowledge archive summary.md guides log; do
  [ -e "doc/$d" ] && echo "衝突: doc/$d ($(find "doc/$d" -type f 2>/dev/null | wc -l) files)"
done
```

結果をユーザーに見せて、**移行対象の合意を取ってからコミット**する。

### Step 1. `utakata doc init`

```bash
utakata doc init
```

**既存ファイルを一切上書きしない。** 欠けているディレクトリと、無い場合の
`utakata.yaml` / `doc/summary.md` / `doc/specs/plan.yaml` だけを作る。
`doc/guides` や `doc/log` が既にあっても中身には触らない。

ここでコミットする(`chore: utakata のワークスペースを追加`)。

### Step 2. `utakata doctor --migrate`

旧レイアウトの移動はこれが担当する。**手で動かす前に必ずこれを通す。**

```bash
utakata doctor --migrate
```

dry-run で移行計画を出したうえで `[y/N]` を聞いてくる。**`n` で一度止めて、
計画をユーザーに見せる。** 承認を得てから `y`。

扱えるもの:

| 移行前 | 移行後 |
|---|---|
| `AI/specs/feature_request.yaml` | `doc/specs/plan.yaml` |
| `AI/logs/conversation_log.md` | `doc/impl/research/`(中身があれば)または削除 |
| `AI/snapshots/` など導出物 | 削除(再生成できるため) |
| `doc/log/raw/**` | `doc/records/log/legacy/`(凍結移動) |
| `doc/log/impl/**` | `doc/impl/` |
| `doc/log/post_contract_summary_*.md` | `doc/impl/research/` |
| `doc/案件整理サマリー*.md` | `doc/summary.md`(リネームのみ) |
| `doc/guides/project/**` | `doc/knowledge/` |
| `doc/guides/{store,payment,infrastructure,testing,troubleshooting}` | `~/.utakata/knowledge/`(横断ナレッジ) |

`△(手動確認要)` と出た項目は自動化されない。**人が判断する前提**なので、
勝手に代行しない。

ここでコミットする(`chore: 旧レイアウトを doctor --migrate で移行`)。

### Step 3. 残った衝突を片付ける

Step 2 が扱わなかった衝突だけが残る。**リネームで避ける。削除しない。**

```bash
git mv doc/<既存> doc/archive/<既存>    # 使わない資料
git mv doc/<既存> doc/knowledge/<既存>  # 案件固有の知識として残す
```

判断はユーザーに聞く。「この資料はもう使わないのか、参照し続けるのか」は
コードから読み取れない。

### Step 4. `utakata claude init`

```bash
utakata claude init
```

**既存ファイルは保護される**(`--force` を付けない限り上書きしない)。

ここに落とし穴がある。**`.claude/settings.json` が既にあると、utakata の
hooks と permissions は追加されない。** 保護された旨が出たら、生成される
内容と既存を突き合わせて**手でマージする**。`--force` で既存の設定ごと
潰さないこと。

既存の hooks を消してよいかは、**必ずユーザーに聞く**。

### Step 5. 検証

```bash
utakata doctor      # 移行漏れ・設定の誤りが出ないこと
utakata check       # 構造とプランの差分
utakata imports     # アーキテクチャ違反(既存コードでは大量に出て当然)
```

`imports` の違反は移行の失敗ではない。utakata を入れる前のコードなのだから
出るのが当たり前で、**この移行で直す対象ではない**。件数を報告して、対応は
別タスクとして切り出す。

`utakata.yaml` の `project.architecture` が実態と合っているかは確認する。
合っていないと `check` も `imports` も無意味な結果を出す。

## やってはいけないこと

- **ユーザーの承認なしにディレクトリを動かす**。棚卸しと計画の提示が先
- **資料を削除する**。使わないものは `doc/archive/` へ移す
- `doctor --migrate` の `△(手動確認要)` を勝手に代行する
- `.claude/settings.json` を `--force` で潰す
- `doc/preview/` に手で書く(生成物なので次の生成で消える)
- `doc/records/` を直接編集する(必ず `utakata log` / `agree` / `message` 経由)
- 移行と同時にコードを直す。**移行だけのブランチに保つ**

## 移行後

`doc/records/` は空から始まる。過去のやり取りを取り込みたい場合は
`utakata message import` / `utakata log import` を使う。ただしこれは
別作業なので、移行ブランチには混ぜない。

`enforcement.impl_plan` は既定 `off`。既存プロジェクトでいきなり `on` に
すると `apply` と `feature add` が全機能で止まる。**移行が落ち着いてから**
ユーザーと相談して切り替える。
