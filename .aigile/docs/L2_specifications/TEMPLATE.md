# Specification Document テンプレート

`.aigile/docs/L2_specifications/<slug>.md` として配置される Specification Document の標準フォーマット。aigile の開発フロー（`docs/workflow.md`）における **Specification Document 作成・更新** の成果物テンプレート。

本ファイル自身（`TEMPLATE.md`）は **テンプレート定義**であり、Specification Document として扱ってはならない（ワークフローは `TEMPLATE.md` を Document スキャン対象から除外する）。

## 配置とファイル名

- パス: `.aigile/docs/L2_specifications/<slug>.md`
- `<slug>` は基本的に依存先 Requirement Document のスラッグと一致させる。
  - 例: `.aigile/docs/L1_requirements/sso-login.md` を満たす Spec → `.aigile/docs/L2_specifications/sso-login.md`
- 1 つの Requirement を複数 Spec に分解する場合は Spec 固有のスラッグを付与し、`depends_on` で対象 Requirement を指定する。
  - 例: `sso-login-flow.md`, `sso-login-error-handling.md` が共に `depends_on: req:sso-login`
- 既存 Document が同一トピックを扱う場合は **新規作成ではなく追記/更新** を選択する（重複 Document を生まない）。

## テンプレート

````markdown
---
node_id: "spec:<slug>"
layer: specification
last_updated: <YYYY-MM-DD>
depends_on:
  - id: "req:<requirement-slug>"
    relation: implements
---

# Specification: <タイトル>

## 概要

<この Specification が提供する振る舞いの要点を 1〜2 行で>

## 対象 Requirement

<満たす Requirement の趣旨と、本 Spec がそのうちのどの部分を担うかを明示>

## 提供する振る舞い

<外部（ユーザー / 他システム）から観測可能な振る舞いを箇条書きで。実装手段は書かない。>

- <振る舞い 1>
- <振る舞い 2>

## 入力 / 出力 / 副作用

- 入力: <ユーザー操作 / API 呼び出し / イベント など>
- 出力: <応答 / 表示 / 通知 など>
- 副作用: <永続化 / 外部呼び出し / 状態遷移 など>

## エラーケース / 例外

- <観測可能な失敗ケースとその振る舞い>

## 非機能要件（必要時）

- 性能: <応答時間 / スループット の指標>
- 可用性: <SLO 等>
- セキュリティ: <認可・暗号化など振る舞い側の要件>

## スコープ外

- <意図的に含めない事項>

## 関連

- 上位 Requirement: `<requirement-slug>` (`.aigile/docs/L1_requirements/<requirement-slug>.md`)
- 関連 Spec: <他の spec があれば>
````

## 記述ルール

- frontmatter は AI が生成・維持する正本（`docs/document-model.md`）。
- `node_id` の slug 部分は **ファイル名と一致** していなければならない（例: `spec:sso-login` ⇔ `sso-login.md`）。
- `depends_on[].id` は **実在する Requirement Document** の `node_id` を指す。リンク切れは後段の Impact Analyzer ワークフローが検出する。
- `last_updated` は bash `date +%Y-%m-%d` で取得した本日の日付を YYYY-MM-DD 形式で記載する。
- **実装手段ではなく振る舞い** を書く。データモデル・技術選定・ライブラリ選択は Architecture Document の責務。
- 既存 Document を更新する場合は、`last_updated` を本日の日付に置き換え、変更箇所を PR 本文の「変更内容」で説明する。

## PR 化のメタデータ

Specification Document を作成・更新する後段ワークフローは、以下のメタデータで PR を発行する想定:

- **タイトル**: `[Specification] <タイトル>`
- **ラベル**: `aigile:pr:spec`, `automation`
- **ベースブランチ**: `main`
- **本文テンプレート**:

```markdown
## 概要

Requirement `req:<requirement-slug>` を受けて、Specification Document を作成 / 更新した。

## 変更内容

- `.aigile/docs/L2_specifications/<slug>.md` を新規作成 / 更新
- <更新の場合は、追加した振る舞い・修正した文言など、差分の要点を 3〜5 件箇条書きで>

## レビューポイント

- 振る舞い記述として読めるか、実装手段に踏み込みすぎていないかを確認してください。
- 上位 Requirement の受け入れ基準を満たす振る舞いになっているかを確認してください。
- 関連 Architecture / 既存 Spec との重複・矛盾がないかを確認してください。

## 関連

- 上位 Requirement: `.aigile/docs/L1_requirements/<requirement-slug>.md`
```
