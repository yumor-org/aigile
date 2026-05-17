# 未確定事項 / 要検討項目

設計議論で未着手のまま残っている論点を記録します。各項目の詳細検討は [discussions/](discussions/) 配下の個別ドキュメントに展開しています。

## 一覧

| # | 項目 | ステータス | 詳細 |
|---|---|---|---|
| 01 | AI 著者と AI 承認者の分離を不変条件に加えるか | 未確定 | [discussions/01-author-approver-separation.md](discussions/01-author-approver-separation.md) |
| 02 | Requirement Issue が "Document 化準備完了" になる判定 | 未確定 | [discussions/02-requirement-ready-trigger.md](discussions/02-requirement-ready-trigger.md) |
| 03 | 実装 Issue（ステップ 9-10）の粒度ガード | 未確定 | [discussions/03-implementation-granularity.md](discussions/03-implementation-granularity.md) |
| 04 | `must_include_agents`（必須レビュアー）の概念 | 採用見送り（拡張余地確保） | [discussions/04-must-include-agents.md](discussions/04-must-include-agents.md) |
| 05 | 外部要因および偶発的発見の扱い (δ1, δ2) | 保留 | [discussions/05-external-and-incidental.md](discussions/05-external-and-incidental.md) |

## ステータスの定義

- **未確定**: 議論を進めて確定すべき項目。実装に着手する前に決定が必要
- **採用見送り（拡張余地確保）**: 今は採用しないが、将来必要になったら後付けできる形を保つ
- **保留**: 当面扱わない。基本フローが安定してから再評価する
- **確定**: 議論完了。本ドキュメントから外し、関連設計ドキュメントへ反映

## 判断タイミングの目安

| # | 判断が必要になるタイミング |
|---|---|
| 01 | AI エージェントが承認者として動作するワークフロー実装前 |
| 02 | `gh aw` ベースの Requirement Issue 分析ワークフロー実装時 |
| 03 | AI 自律実装ワークフロー実装時 |
| 04 | 複合的レビュー要件（特定 AI 観点の必須化）が具体化したとき |
| 05 | 基本フロー（α, β, γ）が安定運用に乗ったとき |

## 議論の進め方

各 `discussions/*.md` は以下の構造で統一されています:

- **背景**: なぜこの論点が浮上したか
- **論点**: 解決すべき問いの明文化
- **選択肢**: 採用可能な案とそれぞれの特性
- **トレードオフ比較**: 表形式で比較
- **暫定推奨 / 暫定判断**: 現時点での推奨
- **判断が必要なタイミング**: いつ確定すべきか
- **残課題**: さらに細部で詰めるべき点
- **関連**: 関連する他ドキュメントへのリンク

新たな未確定項目が浮上した場合は、`discussions/NN-<topic>.md` として追加し、本索引にも追記します。
