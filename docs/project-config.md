# プロジェクト設定

リポジトリ全体に関わる aigile の設定項目を定義します。レイヤーごとの承認ポリシー（[stakeholders.md](stakeholders.md)）やエージェントカタログ（[stakeholders.md](stakeholders.md) を参照）とは別に、プロジェクト固有の振る舞いを宣言します。

## 設定ファイル: `.aigile/config.yml`

プロジェクト全体に関わる設定を集約します。

```yaml
# .aigile/config.yml
repository:
  base_branch: main          # デフォルト: main
```

## `base_branch`: 開発時のベースブランチ

aigile では、Document が **ベースブランチにマージされた状態** を「合意済みの Source of Truth（[concepts.md](concepts.md) 参照）」とみなします。多くのプロジェクトではこれが `main` ですが、`develop`、`master`、`trunk` など別ブランチを採用するチームもあります。

### 既定値

| 設定 | 値 |
|---|---|
| `repository.base_branch` | `main` |

### 設定例

```yaml
# develop ベースのフロー
repository:
  base_branch: develop
```

```yaml
# master 名称を使い続けているプロジェクト
repository:
  base_branch: master
```

### この設定が影響する箇所

| 箇所 | 影響 |
|---|---|
| Document の "合意済み" 判定 | base_branch にマージされた Document = 確定状態 |
| エスカレーションの境界判定 | "対象 Document が base_branch にマージ済みか否か" でフロー分岐（[escalation.md](escalation.md)） |
| Document PR のターゲット | AI が生成する PR は base_branch をターゲットとする |
| 実装 PR のターゲット | 自律実装フェーズで生成される PR も base_branch がターゲット |

### 注意事項

- `base_branch` は **リポジトリで実際に存在するブランチ** を指す必要があります
- ブランチ名を変更する場合は、`base_branch` の更新と GitHub 側のデフォルトブランチ変更を同時に行ってください
- リリースブランチ運用（`release/*`）など、長期分岐を扱う場合の追加設定は将来検討項目です

## 将来の拡張候補

`.aigile/config.yml` は今後以下のような設定を集約する場所として拡張可能です:

- Issue / PR テンプレートのパス指定
- 用語の上書き（"Requirement Document" を別名で呼びたいプロジェクト用）
- AI エージェント実行の許可範囲（特定パスのみ等）
- Spec Kit などの外部ツール連携設定

これらは具体ニーズが出てから設計します（[open-questions.md](open-questions.md) も参照）。
