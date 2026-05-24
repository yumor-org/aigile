# aigile 初期セットアップ

[`cli/install.sh`](install.sh) は aigile の初期セットアップスクリプトです。対象リポジトリの作業ツリーに `.aigile/` 設定、Requirement Issue テンプレート、Requirement Analyzer Agentic Workflow、必要なラベルを配置します。

## 必要要件

- `git` と [`gh`](https://cli.github.com/) が `$PATH` 上にあること
- `gh auth login` 済みであること
- 対象リポジトリが GitHub に push 済み（`gh repo view` で取得できること）

## クイックスタート

セットアップしたいリポジトリのワーキングツリーに移動して、ワンライナーで実行します。

```sh
cd path/to/your-repo
curl -fsSL https://raw.githubusercontent.com/yumor-org/aigile/main/cli/install.sh | bash
```

スクリプトは以下を行います。

1. ベースブランチを GitHub の default branch から検出し、対話で確認
2. 配置プランを表示し確認
3. aigile 本体を depth=1 で temp ディレクトリに clone（永続化しません）
4. 後述のファイル / ディレクトリを配置
5. GitHub ラベルを作成
6. temp ディレクトリを破棄

## 非対話 / 自動化

CI などで自動化したい場合は引数を渡せます。

```sh
curl -fsSL https://raw.githubusercontent.com/yumor-org/aigile/main/cli/install.sh \
  | bash -s -- --yes --base-branch develop
```

### オプション

| オプション | 動作 |
|---|---|
| `-f, --force` | 既存ファイルを上書き（既定: 上書きせずスキップ） |
| `-y, --yes` | 確認プロンプトをスキップ |
| `--base-branch <ref>` | `base_branch` を非対話で指定 |

### 環境変数

| 変数 | 既定 | 用途 |
|---|---|---|
| `AIGILE_REPO` | `yumor-org/aigile` | clone 元リポジトリ（fork 利用時等） |
| `AIGILE_REF`  | `main`             | clone 対象の branch / tag |

## 配置されるもの

| パス | 内容 |
|---|---|
| `.aigile/README.md` | 導入先リポジトリ向けのオンボーディングガイド |
| `.aigile/config.yml` | プロジェクト設定（`base_branch` 等） |
| `.aigile/stakeholders.yml` | レイヤーごとの承認者宣言（既定: 全レイヤー人間レビュー） |
| `.aigile/agents.yml` | AI エージェントカタログ（初期は空） |
| `.aigile/docs/L1_requirements/TEMPLATE.md` | Requirement Document 格納先とテンプレート |
| `.aigile/docs/L2_specifications/TEMPLATE.md` | Specification Document 格納先とテンプレート |
| `.aigile/docs/L3_architectures/TEMPLATE.md` | Architecture Document 格納先とテンプレート |
| `.github/ISSUE_TEMPLATE/aigile-requirement.yml` | Requirement Issue テンプレート |
| `.github/workflows/aigile-requirement-analyzer.md` | Requirement Issue を分析して Ready ラベルを付与する Agentic Workflow |
| `.github/workflows/aigile-requirement-doc-writer.md` | Ready ラベル付与で起動し、Requirement Document PR を発行する Agentic Workflow |
| `.github/workflows/aigile-specification-doc-writer.md` | Req Doc PR マージで起動し、Specification Document の検証・更新 PR を発行する Agentic Workflow |
| `.github/workflows/aigile-architecture-doc-writer.md` | Spec Doc PR マージで起動し、Architecture Document の検証・更新 PR を発行する Agentic Workflow |
| `.github/workflows/aigile-assign-doc-reviewers.yml` | Document PR のラベルから `stakeholders.yml` を参照してレビュアーをアサインする通常 Actions ワークフロー |

### 作成されるラベル

| ラベル | 用途 |
|---|---|
| `aigile:issue:requirement` | Requirement Issue（追加の要求）の識別 |
| `aigile:issue:requirement:ready` | Requirement Document 作成準備が整った Issue |
| `aigile:doc:requirement` | Requirement Document PR の識別（レビュアー割り当てに使用） |
| `aigile:doc:specification` | Specification Document PR の識別 |
| `aigile:doc:architecture` | Architecture Document PR の識別 |
| `automation` | aigile ワークフローが自動発行する PR / Issue の汎用マーカー |

## init 後にやること

1. 配置されたファイルを確認して commit / push する。

   ```sh
   git status
   git add .aigile .github
   git commit -m "chore: bootstrap aigile"
   git push
   ```

2. Agentic Workflow を有効化する。

   ```sh
   gh extension install githubnext/gh-aw
   gh aw compile
   gh aw push
   ```

   Anthropic API キーのシークレット登録など gh-aw 側のセットアップは [githubnext/gh-aw](https://github.com/githubnext/gh-aw) を参照してください。

3. `Issues -> New issue -> "Requirement Issue (追加の要求)"` で要求を起票し、Issue コメントで `aigile` をメンション（`@` 付き）すると Requirement Analyzer が応答します。

## 設計参照

スクリプトが配置する成果物の意味と aigile 全体の設計は以下を参照してください。

- [docs/concepts.md](../docs/concepts.md) — Source of Truth / Issue と Document の分離
- [docs/workflow.md](../docs/workflow.md) — イベント駆動開発フロー（Req → Spec → Arch のカスケード）
- [docs/project-config.md](../docs/project-config.md) — `.aigile/config.yml` 仕様
- [docs/stakeholders.md](../docs/stakeholders.md) — `.aigile/stakeholders.yml` / `agents.yml` 仕様

## 既知の制約

- 本スクリプトは aigile 本体に同梱した bootstrap であり、CLI として常駐するツールではありません。`gh aigile <subcommand>` のような恒久的なコマンド配布は別リポジトリ（gh-aigile）で扱う予定です。
- ブランチプロテクション / Branch Rulesets の設定は対象外です。手動で設定してください。
- マージゲート（`approvers` に基づく承認集計の機械的 enforce）はまだ実装していません（[docs/stakeholders.md](../docs/stakeholders.md) の "マージゲートの扱い" 参照）。
