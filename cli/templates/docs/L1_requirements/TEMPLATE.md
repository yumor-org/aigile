# Requirement Document テンプレート

`.aigile/docs/L1_requirements/<slug>.md` として配置される Requirement Document の標準フォーマット。aigile のイベント駆動フロー（`docs/workflow.md`）における **ステップ 3 (Requirement Document 化)** の成果物テンプレート。

本ファイル自身（`TEMPLATE.md`）は **テンプレート定義**であり、Requirement Document として扱ってはならない（ワークフローは `TEMPLATE.md` を Document スキャン対象から除外する）。

## 配置とファイル名

- パス: `.aigile/docs/L1_requirements/<slug>.md`
- `<slug>` は Issue タイトルから `[REQ]` を取り除き、ASCII 英小文字のケバブケースに変換する。
  - 例: `[REQ] SSO ログイン対応` → `sso-login.md`
  - 例: `[REQ] 通知の頻度を制御したい` → `notification-frequency.md`
- 日本語のみで意味の通る英訳が難しい場合は Issue 番号を併用する。
  - 例: `issue-42-<short-slug>.md`
- 既存 Document が同一トピックを扱う場合は **新規作成ではなく追記/更新** を選択する（重複 Document を生まない）。

## テンプレート

````markdown
---
node_id: "req:<slug>"
layer: requirement
last_updated: <YYYY-MM-DD>
source_issue: <issue 番号>
---

# Requirement: <タイトル（[REQ] プレフィックスは除く）>

## 概要

<Issue の 概要 を整理した文章。1〜2 行。>

## 対象ユーザー (As a ...)

<ペルソナ / ロール。Issue 内容と質問への回答を統合。>

## 要求内容 (I want ...)

<実装手段ではなく振る舞いとして記述。>

## 目的・価値 (So that ...)

<ビジネス価値・ユーザー価値・運用価値のいずれか or 複数。>

## 受け入れ基準 (Acceptance Criteria)

- [ ] <観測可能な条件 1>
- [ ] <観測可能な条件 2>
- [ ] <観測可能な条件 3>

## スコープ外 (Out of Scope)

- <意図的に含めない事項 1>
- <意図的に含めない事項 2>

## 関連

- 起点 Issue: #<issue 番号>
- <Issue の "関連 Document / Issue / PR" セクションで言及されたリンク>

## 議論の経緯

- <Issue コメントスレッドで得られた重要な合意・前提を箇条書きで要約>
- <AI が起票者に確認した主な事項と、得られた結論>
````

## 記述ルール

- frontmatter は AI が生成・維持する正本（`docs/document-model.md`）。手動編集よりもツール経由の更新を優先する。
- `node_id` の slug 部分は **ファイル名と一致** していなければならない（例: `req:sso-login` ⇔ `sso-login.md`）。
- `source_issue` は起点 Issue 番号を整数で指定する（`#` プレフィックスは付けない）。
- `last_updated` は bash `date +%Y-%m-%d` で取得した本日の日付を YYYY-MM-DD 形式で記載する。
- Issue 本文・コメントスレッドで明示されていない事項を勝手に補完しない。事実が不足していれば Requirement Document には進まず、Issue 上で起票者に追加質問する。
- 受け入れ基準は **観測可能な条件** として書く。「実装上の指針」ではなく「満たされたか否かが第三者から判定可能」かを基準にする。
- 関連リンクは Issue 内に書かれたものだけを記載する。捏造禁止。
- Requirement レイヤーの承認は **人間限定（不変条件）** であり、PR のマージをもって受理とみなす（`docs/concepts.md`、`docs/stakeholders.md`）。

## PR 化のメタデータ

Requirement Document を作成する後段ワークフローは、以下のメタデータで PR を発行する想定:

- **タイトル**: `[Requirement] <タイトル>`
- **ラベル**: `aigile:pr:req`, `automation`
- **ベースブランチ**: `main`
- **本文テンプレート**:

```markdown
## 概要

Requirement Issue #<issue 番号> を受けて、Requirement Document を作成した。

## 変更内容

- `.aigile/docs/L1_requirements/<slug>.md` を新規作成 / 更新

## レビューポイント

- Requirement レイヤーは **人間承認が不変条件** です（`docs/concepts.md`、`docs/stakeholders.md`）。
- 振る舞い記述として読めるか、実装に踏み込みすぎていないかを確認してください。
- 受け入れ基準が観測可能な条件として書けているかを確認してください。

## 関連

- 起点: Requirement Issue #<issue 番号>（本 PR のマージで `aigile:issue:status:req-fixed` が起点 Issue に付与され、Specification Document Writer が発火する）
```

備考:
- 旧来は `Closes #<issue 番号>` を本文末尾に置いて Requirement Issue を自動 Close していたが、Requirement Issue は **実装フェーズ完了まで open のまま保持** する方針に変更したため、`Closes/Fixes/Resolves` キーワードは使わない（`docs/concepts.md` の Accepted-Closed の意味論は将来見直し）。
