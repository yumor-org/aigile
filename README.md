# aigile

**AI ネイティブなアジャイル開発の基盤を、あらゆるリポジトリに。**

aigile は、AI と人が協働するアジャイル開発のためのワークフロー基盤を提供するツールです。AI に開発プロセスの一部を委ねつつ、最終的な意思決定と責任は人が持つ ── そのための **高いトレーサビリティ** を備えた開発フローを重視します。

## 目的

ソフトウェア開発に AI を組み込む試みは広がっていますが、以下のような課題が残ります。

- 個々のリポジトリで AI 活用の作法がバラバラで、再現性がない
- AI の意思決定プロセスが不透明で、後から経緯を追えない
- 計画 → 実装 → 振り返り というアジャイルのサイクルに AI が自然に組み込まれていない

aigile は、これらを解決するための **再利用可能なワークフローと規約** を提供し、リポジトリに導入するだけで「AI と一緒にハイレベルなアジャイル開発を行える」状態を即座に獲得できることを目指します。

## 提供するもの

初期フェーズでは、[GitHub Agentic Workflow](https://docs.github.com/) を活用し、リポジトリに導入することで AI が自律的に以下を支援できる基盤を提供します。

### アジャイルサイクル支援ワークフロー
AI が **計画・振り返り・改善** のプロセスを支援します。

- スプリント計画の起案・整理
- イテレーション振り返りの自動収集とサマリ
- 継続的な改善アクションの提案

### トレーサビリティ重視の開発ワークフロー
**「誰が・なぜ・何を決めたか」を追跡可能** に保つための支援を行います。

- Issue / PR / コミット / 意思決定の連結
- AI による提案と人間の判断履歴の明確な分離
- 監査・レビューに耐える形での履歴保全

## 想定利用者

- 中〜大規模のソフトウェア開発を行う **開発チーム**
- AI を活用しつつ品質と説明責任を担保したい **テックリード / スクラムマスター**
- アジャイルの規律を維持したい **個人開発者**

## クイックスタート

aigile を導入したいリポジトリのワーキングツリーで、以下のワンライナーを実行するだけで初期セットアップが完了します。

```sh
cd path/to/your-repo
curl -fsSL https://raw.githubusercontent.com/yumor-org/aigile/main/cli/install.sh | bash
```

`.aigile/` 配下の設定、Issue テンプレート、Requirement Analyzer の Agentic Workflow、関連ラベルが配置されます。詳細・オプション・非対話実行は [cli/README.md](cli/README.md) を参照してください。

> 必要要件: `git` / [`gh`](https://cli.github.com/) （`gh auth login` 済み） / 対象リポジトリが GitHub に push 済みであること

## 設計ドキュメント

aigile の開発フロー、設計判断、設定モデルの詳細は [docs/](docs/) を参照してください。

- [concepts.md](docs/concepts.md) — コアコンセプト（SoT、Issue の 2 種別、不変条件）
- [workflow.md](docs/workflow.md) — 10 ステップ開発フローと全体図
- [layers.md](docs/layers.md) — 4 層 Document モデルと Spec Kit マッピング
- [stakeholders.md](docs/stakeholders.md) — 承認モデルと設定ファイル仕様
- [project-config.md](docs/project-config.md) — プロジェクト全体設定（ベースブランチ等）
- [escalation.md](docs/escalation.md) — エスカレーション機構
- [open-questions.md](docs/open-questions.md) — 未確定事項

## ステータス

🚧 **本プロジェクトは初期構築フェーズです。** 仕様・インターフェースは大きく変わる可能性があります。

## ライセンス

[MIT License](LICENSE)
