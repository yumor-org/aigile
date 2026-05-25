# .aigile/

このディレクトリは [aigile](https://github.com/yumor-org/aigile) をこのリポジトリに導入したことで配置された設定・ドキュメント領域です。aigile は AI ネイティブなアジャイル開発の基盤を提供する仕組みで、計画・要求整理・実装までを **トレーサビリティを保ったまま AI と協働する** ことを目指しています。

このファイルは aigile を導入したこのリポジトリで開発を進めるための入り口です。aigile 自体の設計思想・全体仕様については [aigile 本体のドキュメント](https://github.com/yumor-org/aigile/tree/main/docs) を参照してください。

## このディレクトリの中身

| パス | 役割 |
|---|---|
| [config.yml](config.yml) | プロジェクト設定。aigile が Source of Truth として扱うベースブランチなどを宣言する。 |
| [stakeholders.yml](stakeholders.yml) | Document レイヤーごとの承認ポリシー（誰がレビュー権限を持つか）。 |
| [agents.yml](agents.yml) | このリポジトリで利用できる AI エージェントのカタログ。 |
| [docs/L1_requirements/](docs/L1_requirements/) | Requirement Document の格納先。マージされた Document が「合意済みの要求」を表す。`TEMPLATE.md` が標準フォーマットを兼ねる。 |
| [docs/L2_specifications/](docs/L2_specifications/) | Specification Document の格納先。`TEMPLATE.md` が標準フォーマットを兼ねる。 |
| [docs/L3_architectures/](docs/L3_architectures/) | Architecture Document の格納先。`TEMPLATE.md` が標準フォーマットを兼ねる。 |

加えて、リポジトリ直下に以下が配置されています。

| パス | 役割 |
|---|---|
| `.github/ISSUE_TEMPLATE/aigile-requirement.yml` | Requirement Issue（追加の要求）の起票テンプレート。 |
| `.github/workflows/aigile-requirement-analyzer.md` | Requirement Issue を分析する Agentic Workflow の定義。 |

## 開発フロー（要点）

aigile では Issue（提案・報告）と Document（合意済みの契約）を分け、ベースブランチにマージされた Document を Source of Truth として扱います。Requirement Issue を起点に、3 つの Document レイヤー（Req → Spec → Arch）が **Issue 上のステータスラベルでカスケードする** 形で進みます。

1. **人間**: `New issue` → `Requirement Issue (追加の要求)` で要求を起票する（自動で `aigile:issue:req` が付与される）。
2. **AI**: Requirement Analyzer が Issue にコメントで質問を返す。Issue コメントで `@aigile` をメンションすると応答が起動する。
3. **人間**: AI の質問に Issue 上で回答し、要求の輪郭を確定させる。Ready 判定時に Analyzer が `aigile:issue:status:req-analyzed` を付与する（または人手で付与）。
4. **AI**: Requirement Document（[docs/L1_requirements/](docs/L1_requirements/)）を起こす PR (`aigile:pr:req`) を発行する。
5. **人間**: PR をレビューしてマージする。`aigile-mark-doc-fixed` が起点 Issue に `aigile:issue:status:req-fixed` を自動付与する。
6. **AI**: Specification Document Writer が発火し、Specification Document の検証・更新 PR (`aigile:pr:spec`) を発行する（影響なしの場合はログのみ）。
7. **人間**: Spec PR をレビューしてマージする。同様に `aigile:issue:status:spec-fixed` が起点 Issue に付与される。
8. **AI**: Architecture Document Writer が発火し、Architecture Document の検証・更新 PR (`aigile:pr:arch`) を発行する。
9. **人間**: Arch PR をレビューしてマージする。`aigile:issue:status:arch-fixed` が付与され、Doc カスケードは終端に達する。

起点 Requirement Issue は **実装フェーズが完了するまで open のまま** 保持されます（旧来は Req Doc マージで自動 Close していましたが、ステータスラベルで進行が表現されるため変更されました）。

フロー全体・Specification / Architecture 以降の流れ・エスカレーション機構は [workflow.md](https://github.com/yumor-org/aigile/blob/main/docs/workflow.md) と [escalation.md](https://github.com/yumor-org/aigile/blob/main/docs/escalation.md) を参照してください。

## クイックスタート

### 1. Agentic Workflow を有効化する

aigile の AI エージェントは [GitHub Agentic Workflow](https://github.com/githubnext/gh-aw) として動きます。最初の 1 回だけ次を実行してください。

```sh
gh extension install githubnext/gh-aw
gh aw compile
gh aw push
```

Anthropic API キーなどシークレットの設定は [githubnext/gh-aw](https://github.com/githubnext/gh-aw) の手順に従ってください。

### 2. 最初の Requirement Issue を起票する

GitHub の `Issues` → `New issue` → `Requirement Issue (追加の要求)` を選び、要求内容・対象ユーザー・目的・受け入れ基準を埋めて起票します。

### 3. AI と対話して要求を磨く

Issue が立つと Requirement Analyzer が自動でコメントに質問を残します。以後、Issue コメントで `@aigile` をメンションすると再度応答します。要求が確定したらリリース計画のタイミングで `aigile:issue:status:req-analyzed` を付与します。

## 設定をカスタマイズする

| やりたいこと | 編集するファイル |
|---|---|
| Source of Truth とするベースブランチを変える | [config.yml](config.yml) |
| Document レイヤーごとの承認者・承認方式を変える | [stakeholders.yml](stakeholders.yml) |
| AI レビューや独自エージェントを追加する | [agents.yml](agents.yml) と [stakeholders.yml](stakeholders.yml) |

各ファイルの仕様は本体ドキュメントを参照してください。

- [project-config.md](https://github.com/yumor-org/aigile/blob/main/docs/project-config.md) — `config.yml` の仕様
- [stakeholders.md](https://github.com/yumor-org/aigile/blob/main/docs/stakeholders.md) — `stakeholders.yml` と `agents.yml` の仕様

> **不変条件**: Requirement レイヤーの承認者は人間限定です。AI 承認の導入は Specification / Architecture レイヤー以降に限られます。詳細は [concepts.md](https://github.com/yumor-org/aigile/blob/main/docs/concepts.md) の "不変条件" を参照してください。

## さらに知るために

- [concepts.md](https://github.com/yumor-org/aigile/blob/main/docs/concepts.md) — SoT / Issue と Document の分離 / 不変条件
- [workflow.md](https://github.com/yumor-org/aigile/blob/main/docs/workflow.md) — イベント駆動開発フロー
- [layers.md](https://github.com/yumor-org/aigile/blob/main/docs/layers.md) — 3 層 Document モデル
- [document-model.md](https://github.com/yumor-org/aigile/blob/main/docs/document-model.md) — frontmatter スキーマと依存関係の宣言規約
- [stakeholders.md](https://github.com/yumor-org/aigile/blob/main/docs/stakeholders.md) — 承認モデルと設定仕様
- [escalation.md](https://github.com/yumor-org/aigile/blob/main/docs/escalation.md) — エスカレーション機構

## ステータス

🚧 aigile は初期構築フェーズのため、テンプレートやワークフローの仕様は今後変更される可能性があります。最新の挙動については上記の本体ドキュメントを参照してください。
