# doc/impl/ — feature 実装計画のライフサイクル

規模のある feature は、コードを書く前に**実装計画**を作ります。
計画は `doc/impl/<レーン>/PLAN-NNNN_{feature}.md` に置かれ、
状態が変わるとファイルがレーン(サブディレクトリ)間を移動します。

```sh
utakata doc show impl    # このドキュメントを表示
```

---

## 状態は2軸

```yaml
status: in_progress   # todo | in_progress | review | done | archived
test:   todo          # not_required | todo | in_progress | review | done
```

- **`status`** — 実装そのものの進行。`review` は**自分のレビュー段階**です
- **`test`** — 検証の進行。`not_required` は「テストは不要」と**明示**する値で、
  「まだ決めていない(`todo`)」と区別されます

1本の列にまとめない理由: 「実装完了・テスト未着手」と「実装レビュー中」が
同じ位置になってしまい、テストが落ちて実装へ戻る動きも表現できないためです。

---

## レーン(ディレクトリ)は2軸から導出される

```
doc/impl/
├── 1_todo/                # status: todo
├── 2_in_progress/         # status: in_progress
├── 3_review/              # status: review
├── 4_test_todo/           # status: done かつ test: todo
├── 5_test_in_progress/    # status: done かつ test: in_progress
├── 6_test_review/         # status: done かつ test: review
├── 7_done/                # status: done かつ test: done | not_required
└── archive/               # status: archived
```

導出の規則は「**今どこで止まっているか**」です:

1. 実装が終わっていない → 実装側のレーン(1〜3)
2. 実装は終わったが検証が残っている → テスト側のレーン(4〜6)
3. 両方終わった → `7_done`

### 正は frontmatter、ディレクトリは導出

ディレクトリと frontmatter の**両方を正にはしません**(食い違ったときに
どちらを信じるか決められなくなるため)。コマンドは frontmatter を更新して
から移動するので1操作で両方が揃います。手でファイルを動かした場合は:

```sh
utakata impl sync --dry-run   # 何が動くか確認
utakata impl sync             # frontmatter に合わせて再配置
```

`utakata doctor` も乖離を検出して案内します。

---

## コマンド

```sh
# 作成
utakata impl new <feature> [--agreement AGR-003] [--spec <path>] [--basis client_agreed]

# 実装軸
utakata impl start <ID>      # → in_progress
utakata impl review <ID>     # → review(自分のレビュー)
utakata impl done <ID>       # → done(完了日を記録)

# 検証軸(実装が done になってから)
utakata impl test start <ID>
utakata impl test review <ID>
utakata impl test done <ID>
utakata impl test todo <ID>                    # 差し戻し
utakata impl test skip <ID> --reason "設定変更のみ"

# 参照
utakata impl list [--status <s>] [--test <s>] [--lane <lane>] [--json]
utakata impl board            # レーン別ボード(doc/preview/impl_board.md を再生成)

utakata impl archive <ID>     # 参照しなくなったら archive/ へ
                              # 戻すときは utakata impl start <ID> 等で通常の遷移
utakata impl sync [--dry-run]
```

### 逆行は許可されています

`done` にした後で `utakata impl start` を実行すれば `2_in_progress` に戻ります。
テストが落ちて実装に戻るのは正常な流れであり、一方通行にすると現実の作業を
記録できなくなるためです。

ただし**検証軸は実装が `done` になるまで進められません**(実装が終わって
いないのにテスト完了はあり得ないため)。`--force` は用意していません。

### 壊れた計画・重複 ID は動かさない

frontmatter が読めない計画(手編集で YAML を壊した等)は一覧・採番から
外れますが、**`utakata doctor` が件数とパスを報告**します(黙って消えると
ID が再利用されて別の計画を上書きするため)。同じ ID のファイルが複数ある
場合も同様に報告し、遷移・移動は拒否されます — どちらを残すかは人が決めます。

移動先に同名ファイルが既にある場合、`impl sync` はそれを**上書きせずスキップ**
して報告します(exit 1)。

### ボードは自動で最新に保たれる

状態を変えるコマンド(`start` / `review` / `done` / `test *` / `archive` /
`sync` / `new`)は、実行後に `doc/preview/impl_board.md` を再生成します。
手動で再生成する必要はありません。

---

## `enforcement.impl_plan` — 計画なしの実装を止める

`utakata.yaml`:

```yaml
enforcement:
  impl_plan: "on"     # 既定は off
```

`on` にすると、`utakata apply --scope feature` と `utakata feature add` が
**feature 単位で**ゲートします:

- **これから新規に**スキャフォールドする feature に、archived でない計画が
  無ければ、その feature だけスキップして `utakata impl new <feature>` を案内
- 他の feature の生成は通常どおり進む(1つ欠けただけで全体を止めない)
- 1件でもスキップしたら exit 1(CI で気づける)
- **既にディスクにある feature には作用しません**(これから実装を始める
  わけではないため)

計画の有無は「archived 以外の計画が1つでもあるか」で判定します。`done` でも
満たします — 細かすぎる要求は運用を殺すためです。

CLI を通さずに直接コードを書いた場合はゲートできないので、
`utakata doctor` が「実装があるのに実装計画が無い feature」を情報として
報告します。

---

## frontmatter

```yaml
---
id: PLAN-0001
feature: login
status: in_progress
created: 2026-08-11
origin:                    # 根拠へのリンク
  agreements: [AGR-003]
  specs: []
  messages: [MSGR-20260811-001]
basis: client_agreed       # client_agreed | developer_judgment
test:
  status: todo
  static: pending          # 自動検証(flutter analyze / utakata check)
  on_device: pending       # 実機確認
completed_on: 2026-08-20   # done のときだけ書かれる(戻すと消える)
---
```

`skip_reason` は `test: not_required` のときだけ書かれ、他の状態へ移ると消えます。
`static` / `on_device` は `impl test done` で `done` になり、差し戻すと `pending` に戻ります。

本文(Markdown)は人間/AI の自由記述領域です。**frontmatter は CLI が
機械管理する**ので手で編集せず、コマンドで遷移させてください
(編集してしまった場合は `utakata impl sync` で配置を戻せます)。

---

## v1.6.x からの移行

- `status: draft` は `todo` として読まれます(書き戻しは `todo`)
- 旧 `verification:`(`static` / `on_device`)は `test:` に統合されます。
  両方 `done` なら `test: done` として読まれます
- フラット配置(`doc/impl/*.md`)のままでも読めます。
  `utakata impl sync` でレーンへ移動できます
