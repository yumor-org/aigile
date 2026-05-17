# 01. AI 著者と AI 承認者の分離を不変条件に加えるか

**ステータス**: 未確定
**関連**: [stakeholders.md](../stakeholders.md), [concepts.md](../concepts.md)

## 背景

aigile のフローでは、Requirement Document、Specification Document、Architecture Document などのほとんどの Document PR は AI が著者として作成します。同時に [stakeholders.md](../stakeholders.md) の設計では、これらの Document の承認者として AI エージェントを指定することが許されています（Requirement レイヤーを除く）。

このとき、ソフトウェア工学の伝統的な **separation of duties**（職務分掌）の観点では、「同一主体が著者かつ承認者」になることは品質保証の観点で問題視されます。aigile では人間に対してはこの原則を強制すべきですが、AI に対しても同様の制約を設けるかが論点です。

## 論点

**AI が著者の PR を、同一の AI（あるいは AI のみの集合）が承認することを、構造的に禁止すべきか？**

具体的には:

- Spec PR を AI が作成し、別の AI エージェント（spec-security-reviewer 等）が承認する → 著者は AI、承認者も AI。これは separation of duties に違反するか？
- 同一の AI モデル/エージェントが同一 PR の著者かつ承認者になるケースをどう扱うか？

## 選択肢

### (a) 全レイヤーで「AI 著者の PR は AI のみでは承認不可」を構造保証

- 著者 AI と承認者 AI が同一インスタンスであろうとなかろうと、AI のみの組み合わせは承認成立しない
- 必ず 1 名以上の人間承認が必要
- **影響**: AI 自律性の縮小、リポジトリのスループット低下

### (b) Requirement 層のみ「人間承認必須」、他はポリシーに委ねる（現状の設計）

- Requirement 層は既に `approver_type: human` 固定
- Spec, Architecture, Details は `.aigile/stakeholders.yml` でプロジェクトが選択可能
- **影響**: 柔軟だが設定ミスや過信のリスクあり

### (c) 「著者 AI と承認者 AI は別エージェントでなければならない」をルール化

- 同一 PR 内で、著者 AI のエージェント名 = 承認者 AI のエージェント名 となる組合せを禁止
- ただし「別 AI エージェントなら AI のみで承認成立」は許す
- **影響**: 自己承認の循環構造は防げるが、共謀的承認（同じ訓練データ・同じプロンプト系統）は止められない

### (d) 「観点が異なる複数の AI エージェントによるコンセンサス必須」をルール化

- 例: Spec の承認には security 観点と performance 観点の AI 双方の承認が必要
- これは [04-must-include-agents.md](04-must-include-agents.md) の議論と密接に関連

## トレードオフ比較

| 選択肢 | 安全性 | 自律性 | 柔軟性 | 実装複雑度 |
|---|---|---|---|---|
| (a) AI のみ承認を全面禁止 | ◎ | × | × | 低 |
| (b) 現状（Requirement のみ人間必須） | ○ | ◎ | ◎ | 低 |
| (c) 著者 = 承認者の同一エージェント禁止 | ○ | ○ | ○ | 中 |
| (d) 複数観点 AI コンセンサス必須 | ○ | ○ | ○ | 高 |

## 暫定推奨

現状は **(b)** のまま、ただし「(c) の同一エージェント自己承認禁止」は **低コストで強い安全性向上を得られる** ため、追加検討の価値があります。

具体的には:

- `.aigile/stakeholders.yml` の `eligible.ai_agents` に列挙された AI エージェントは、その PR の著者エージェントと同一でないことをツール側で保証
- 著者エージェントを PR 本文の構造化メタデータから読み取り、承認時に突き合わせ

## 判断が必要なタイミング

- AI エージェントが承認者として実際に動作するワークフローを実装するタイミング
- 最初の `gh aw` ベースのレビュー自動化を組む直前

## 関連する不変条件

現状で確定している不変条件:

- Requirement レイヤーの承認者は人間に限定（[concepts.md](../concepts.md), [stakeholders.md](../stakeholders.md)）
- 下位作業の中間生成物は使い捨て可能（[concepts.md](../concepts.md)）

本論点が確定すれば、3 番目の不変条件として「著者 AI と承認者 AI は異なるエージェントでなければならない」を追加できます。
