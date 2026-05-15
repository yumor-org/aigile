# 04. `must_include_agents`（必須レビュアー）の概念

**ステータス**: 採用見送り（将来拡張として保留）
**関連**: [stakeholders.md](../stakeholders.md), [01-author-approver-separation.md](01-author-approver-separation.md)

## 背景

`.aigile/stakeholders.yml` では、各 Document レイヤーの承認者として `eligible` リスト（承認可能な主体の集合）と `required_approvals`（必要な承認数）を定義しています。

```yaml
specification:
  approver_type: human_or_ai
  required_approvals: 2
  eligible:
    humans: ["@tech-leads"]
    ai_agents: ["spec-security-reviewer"]
```

この現状の設計では、「**承認は eligible リストから任意の組合せで required_approvals 数だけ集まればよい**」というルールです。

しかし運用上、「**特定の AI エージェントは必ずレビューに含めなければならない**」という要件が出てくる可能性があります。例えば:

- `constitution-guardian`（プロジェクト原則の準拠チェック AI）は全レイヤーで必須
- `security-reviewer` は Architecture レイヤーで必須
- `accessibility-reviewer` は UI 関連の Spec で必須

これを表現する仕組みとして `must_include_agents` フィールドを導入するか、が論点です。

## 論点

**特定のレビュアー（AI または人間）を必須として指定する仕組みを `stakeholders.yml` に持ち込むか？**

## 設計案

```yaml
specification:
  approver_type: human_or_ai
  required_approvals: 2
  eligible:
    humans: ["@tech-leads"]
    ai_agents: ["spec-security-reviewer", "spec-perf-reviewer"]
  must_include_agents: ["constitution-guardian"]   # ← 必須レビュアー
```

セマンティクス:

- `must_include_agents` に列挙されたエージェントの承認なしには、たとえ `required_approvals` 数を満たしても PR はマージ不可
- これらは `required_approvals` のカウントに含まれる（つまり 2 承認のうち 1 は constitution-guardian、もう 1 は他のレビュアー）
- 該当エージェントが拒否（Request Changes）した場合は PR は明示的にブロック

## 選択肢

### (a) 採用する

- 複合的なレビュー要件（"人間 + 特定 AI 観点"）を一級概念で表現できる
- セキュリティ・コンプライアンス系の要件を構造的に保証できる

### (b) 採用しない（現状維持）

- `required_approvals` と `eligible` の組合せで運用回避可能（例: eligible にその AI のみ列挙、required_approvals 1）
- ただしこれだと「constitution-guardian と人間 1 名の承認が必要」という要件が表現できない

### (c) 採用見送りだが、将来拡張可能な形を確保

- 現状の `stakeholders.yml` スキーマに `must_include_agents` 用の予約フィールドを置かない
- 必要になった時点で後方互換を保ちつつ追加可能な設計を維持

## トレードオフ比較

| 選択肢 | 表現力 | 仕様複雑度 | 設定者の学習コスト | 採用判断の根拠 |
|---|---|---|---|---|
| (a) 採用 | ◎ | 高 | 高 | 早期に複合要件が出る場合 |
| (b) 採用しない | △ | 低 | 低 | 要件が単純な場合 |
| (c) 見送りつつ拡張余地確保 | 現状: 低 / 将来: ◎ | 低 | 低 | 要件が現時点で不明な場合 |

## 暫定判断

**(c) 採用見送り、ただし将来拡張可能な形で保留**。

理由:

- aigile はまだ初期構築フェーズ。具体的な運用要件が見えてから機能を追加するほうが、不要な複雑性を避けられる
- 現時点で `must_include_agents` を必要とする具体的シナリオが固まっていない
- `stakeholders.yml` のスキーマに「未知のキーを許容する」設計にしておけば、後付けで追加可能

`stakeholders.yml` のパーサ実装側で:

- 既知フィールドの validation
- 未知フィールドは warning だけ出して無視（または将来拡張用に保持）

という方針を取れば、将来の機能追加が破壊的変更にならずに済みます。

## 採用すべきトリガ

以下のいずれかが具体化したら、本論点を再評価して採用を検討します:

1. プロジェクトが「特定 AI による事前チェックを承認条件に含めたい」と明確に要求した
2. 監査・コンプライアンス要件で「特定観点のレビューを構造保証する必要」が出た
3. [01-author-approver-separation.md](01-author-approver-separation.md) で「複数観点 AI コンセンサス」を採用する方向になった

## 関連

- [01-author-approver-separation.md](01-author-approver-separation.md): 「複数観点 AI コンセンサス必須」の選択肢と密接に関連
- [stakeholders.md](../stakeholders.md): 承認モデルの現状仕様
