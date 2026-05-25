# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## このリポジトリの性質

aigile は **AI ネイティブなアジャイル開発の基盤を、他のリポジトリに配布する側のリポジトリ** です。実行時バイナリやサービスではなく、以下を提供します:

- 設計仕様としての Markdown ドキュメント群（[docs/](docs/)）
- 導入先リポジトリへ bootstrap を行うシェルスクリプト（[cli/install.sh](cli/install.sh)）
- 配布される雛形（[cli/templates/](cli/templates/)）
- GitHub Agentic Workflow (`gh aw`) 定義（[.github/workflows/](.github/workflows/)）

ユーザーは `curl ... install.sh | bash` で自分のリポジトリにファイル群とラベルを配置します。**ここで編集した内容は、エンドユーザーが install を再実行するまでは波及しません。**

## 3 つの「ドキュメント・テンプレート」ツリーを混同しない

このリポジトリ内には、似たディレクトリ名で **役割が完全に異なる 3 つのツリー** が並存します。AI が無意識に取り違えやすい最大のポイントです。

| パス | 役割 | 編集の意味 |
|---|---|---|
| [docs/](docs/) | **aigile 自体の設計仕様**（コアコンセプト、ワークフロー定義、レイヤー仕様等） | aigile の仕様変更 |
| [.aigile/](.aigile/) | このリポジトリ **自身が aigile を適用した結果**（セルフホスト用設定。`.aigile/docs/` 下の各レイヤーには現状 `TEMPLATE.md` のみ） | この repo の開発フローに対する設定変更 |
| [cli/templates/](cli/templates/) | **install.sh が他リポジトリへコピーする雛形** | エンドユーザーへの配布物の変更 |

特に注意:

- 仕様（`docs/`）を変えても配布物（`cli/templates/`）は自動追随しません。両方を同時に更新する必要があるか毎回確認すること。
- `cli/templates/` に **新規ファイル** を追加した場合は、以下 3 箇所をすべて更新する必要があります（どれか 1 つを忘れると配布されない or プラン表示と実体がズレる）:
  1. [cli/install.sh:206-222](cli/install.sh#L206-L222) の `install_file` 呼び出し列（実コピー定義）
  2. [cli/install.sh:172-187](cli/install.sh#L172-L187) の Plan 表示用 `log_step` 列
  3. [cli/README.md](cli/README.md) の「配置されるもの」テーブル
- `cli/templates/` 配下は基本 `docs/L{1,2,3}_*/TEMPLATE.md` 系ですが、`cli/templates/readme.md`（→ `.aigile/README.md` にコピー）のような `docs/` 配下でないテンプレートも存在します。新規追加時はコピー先パスを `install_file` の第 2 引数で明示すること。

## GitHub Workflows の二系統

[.github/workflows/](.github/workflows/) には性質の異なる 2 種類のワークフローが同居しています。

### gh-aw（GitHub Agentic Workflow）

- `*.md` がソース、`*.lock.yml` が `gh aw compile` で生成された成果物
- 4 本: `aigile-requirement-analyzer`, `aigile-requirement-doc-writer`, `aigile-specification-doc-writer`, `aigile-architecture-doc-writer`
- `.lock.yml` は [.gitattributes](.gitattributes) で `linguist-generated=true merge=ours` 指定済み。**手で編集しない**こと。`.md` を編集したら `gh aw compile` で再生成する
- アクション固定情報は [.github/aw/actions-lock.json](.github/aw/actions-lock.json)

### 通常の GitHub Actions

- `aigile-assign-doc-reviewers.yml` は通常の Actions ワークフロー。`pull_request_target` でベースブランチの `.aigile/stakeholders.yml` を参照して PR レビュアーをアサインする
- フォーク PR からの攻撃面を避けるため、**PR 提供コードは実行しないように base ブランチを checkout** している。この性質を壊す変更は避けること

## アーキテクチャの中核モデル

aigile の設計判断はすべて以下のモデルに収束します。詳細は対応ドキュメントを参照してください。

- **Document = Source of Truth**: ベースブランチにマージされた Document のみが「合意済み」（[docs/concepts.md](docs/concepts.md)）
- **3 レイヤー Document モデル**: Requirement (L1) → Specification (L2) → Architecture (L3)（[docs/layers.md](docs/layers.md)）
- **依存方向は下位 → 上位の単方向のみ**: frontmatter `depends_on` は L2/L3 のみが持ち、L1 には書かない。逆引きは grep で都度計算（[docs/document-model.md](docs/document-model.md)）
- **`node_id` の slug 部分はファイル名と一致**（grep ベースの依存解決の前提）
- **イベント駆動カスケード**: Issue → Req Doc PR → merge → Spec Doc PR → merge → Arch Doc PR（[docs/workflow.md](docs/workflow.md)）
- **不変条件**: Requirement レイヤーの承認者は **人間限定**。設定で AI に渡そうとしても aigile が無効化する（[docs/stakeholders.md](docs/stakeholders.md)）

「議論済みだが未確定」「採用見送り」の論点は [docs/open-questions.md](docs/open-questions.md) と [docs/discussions/](docs/discussions/) に集約しています。設計変更を提案する前に既存の議論を確認すること。

## install.sh への変更を扱うときの注意

[cli/install.sh](cli/install.sh) は **`curl ... | bash` でパイプ経由実行される**（スクリプト自身が stdin を占有するため、対話入力を `read` で奪えない）想定です。以下の制約を満たすこと:

- 対話プロンプトは `/dev/tty` を直接読む（[cli/install.sh:52-63](cli/install.sh#L52-L63) の `prompt()`、[cli/install.sh:65-81](cli/install.sh#L65-L81) の `confirm()` 参照）。`read` を直接使わない
- `set -euo pipefail` 前提でエラーパスを書く
- 既存ファイルは既定でスキップ、`--force` のときだけ上書き（[cli/install.sh:85-107](cli/install.sh#L85-L107)）
- aigile 本体は `--depth 1` の temp clone で取得し、`trap 'rm -rf "$tmp"' EXIT` で必ず破棄する。永続化しない
- 変更後は **GitHub に push 済みの空に近いテストリポジトリで実際に curl + bash** して動作確認することを推奨（unit test の枠組みはまだ無い）

## 言語ポリシーと表記

- ドキュメント、コミットメッセージ、PR タイトル/本文、Issue テンプレートはすべて **日本語**
- コード（シェル、YAML、フロントマター、識別子）と Workflow の `name:` などの仕組み側の値は **英語**
- 著作権・帰属表記が必要な場合は `DATE YUKI`（大文字・半角スペース区切り）を使用する
- コミットメッセージに `Co-Authored-By` 行を付けない

## 開発タスクとしての共通操作

| やりたいこと | コマンド / 操作 |
|---|---|
| gh-aw ワークフロー `.md` を変更した | `gh aw compile` で対応 `.lock.yml` を再生成（`gh extension install githubnext/gh-aw` 済みである必要あり） |
| install.sh の挙動を試す | テスト用 GitHub リポジトリで `AIGILE_REPO=<your-fork> AIGILE_REF=<branch> bash cli/install.sh` |
| シェルスクリプトを静的検査 | `shellcheck cli/install.sh`（任意） |
| Document テンプレートの妥当性確認 | `cli/templates/docs/L*/TEMPLATE.md` の frontmatter サンプルが [docs/document-model.md](docs/document-model.md) のスキーマに従っているか目視確認 |

build / test / lint の自動化はまだ整備されていません。新規導入する場合は本ファイルに追記してください。

## 設計仕様への入り口

詳細は次のドキュメントを直接読むこと（重複転載しない）:

- [docs/concepts.md](docs/concepts.md) — SoT / Issue と Document の分離 / 不変条件
- [docs/workflow.md](docs/workflow.md) — トリガー・アクター表とカスケード図
- [docs/layers.md](docs/layers.md) — 3 層モデルと Spec Kit マッピング
- [docs/document-model.md](docs/document-model.md) — frontmatter スキーマと依存関係
- [docs/stakeholders.md](docs/stakeholders.md) — 承認モデルと `stakeholders.yml` / `agents.yml` 仕様
- [docs/project-config.md](docs/project-config.md) — `.aigile/config.yml` 仕様
- [docs/escalation.md](docs/escalation.md) — エスカレーション機構
