# Document モデル: frontmatter と依存関係

[layers.md](layers.md) で定義した 3 レイヤー Document の **メタデータと依存関係の表現規約** を定義します。レイヤーの責務分担はレイヤーモデル側に、本ドキュメントは「ファイルにどう書くか」「依存をどう辿るか」「変更影響をどう求めるか」に集中します。

## 設計目標

aigile の Document 群は、要求の追加・変更があった際に **「どの既存 Document に影響するか」を AI が機械的に検出** できる状態を目指します。これを満たすため、次の 3 原則を採用します:

1. **依存関係を frontmatter で機械可読に宣言する**（人間が本文中のリンクを目で辿らない）
2. **依存方向は下位 → 上位の単方向のみ**（双方向で書かない）
3. **影響範囲分析を Green / Amber / Gray の 3 帯域で分類する**（自動更新可能なものと人間判断が要るものを分ける）

## 適用範囲

本規約は以下のファイル群に適用されます:

- `.aigile/docs/L1_requirements/<slug>.md`
- `.aigile/docs/L2_specifications/<slug>.md`
- `.aigile/docs/L3_architectures/<slug>.md`

## frontmatter スキーマ

すべての Document ファイルは先頭に YAML frontmatter ブロックを持ちます。フィールドは **ネームスペースなしでトップレベル** に配置します。

### 共通フィールド（全レイヤー必須）

| フィールド | 型 | 説明 |
|---|---|---|
| `node_id` | string | Document の一意識別子。`<layer-prefix>:<slug>` 形式 |
| `layer` | enum | `requirement` / `specification` / `architecture` |
| `last_updated` | date (YYYY-MM-DD) | 本ファイルが最後に更新された日付 |

ライフサイクル状態（Draft / Approved 等）は frontmatter には持たせません。PR の open / merged 状態と git 履歴が同等以上の情報を提供するため、二重管理を避ける判断です。

### Requirement 固有

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `source_issue` | int | ✓ | 起点となる Requirement Issue 番号 |

Requirement は最上流のため `depends_on` は **持ちません**（書かれていても無視されます）。

### Specification / Architecture 固有

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `depends_on` | list | ✓ | 上位レイヤー Document への依存リスト |
| `depends_on[].id` | string | ✓ | 依存先 Document の `node_id` |
| `depends_on[].relation` | enum | ✓ | 関係種別（下表参照） |

## node_id 命名規約

`node_id` の形式は `<layer-prefix>:<slug>` です。

| レイヤー | プレフィックス | 例 |
|---|---|---|
| Requirement | `req:` | `req:sso-login` |
| Specification | `spec:` | `spec:sso-login` |
| Architecture | `arch:` | `arch:sso-login` |

**制約**: `slug` 部分は **ファイル名（拡張子なし）と一致** していなければなりません。例えば `req:sso-login` は `.aigile/docs/L1_requirements/sso-login.md` を指します。この制約により、依存先の解決が grep 一発で可能になります。

`node_id` のプレフィックス（`req:` / `spec:` / `arch:`）と物理ディレクトリのプレフィックス（`L1_` / `L2_` / `L3_`）は独立した語彙です。両者を相互参照する場合の対応関係は次のとおり:

| レイヤー | ディレクトリ | node_id プレフィックス |
|---|---|---|
| Requirement | `L1_requirements/` | `req:` |
| Specification | `L2_specifications/` | `spec:` |
| Architecture | `L3_architectures/` | `arch:` |

## relation 語彙

`depends_on[].relation` の取りうる値:

| 関係 | from | to | 意味 |
|---|---|---|---|
| `implements` | spec | req | この Spec は当該 Requirement の振る舞いを実現するために存在する |
| `realizes` | arch | spec | この Architecture は当該 Spec を実現する構造を提供する |
| `constrained_by` | arch | req | 横断的な要求制約（性能・セキュリティ等）を直接受ける場合のみ。通常は省略 |

`constrained_by` は例外的用途です。基本は `spec → req` と `arch → spec` の 2 種で足ります。

## 依存方向の原則: 下位 → 上位の単方向

frontmatter には **下位 → 上位** の依存のみ書きます。上位レイヤーの Document には下位への参照を **書きません**。

- 理由 1: 双方向で書くと二重保守になり、片側が古くなる
- 理由 2: 「Requirement が変わったとき何に波及するか」は下位の frontmatter を grep すれば求まる（逆引きインデックスは下位の宣言の派生物）
- 理由 3: 上位 Document の意味論を「下位のために存在する」にしない（Requirement は実装を知らずに成立する）

## 逆引きインデックス

「ある Requirement が変わったとき、影響を受ける Spec/Arch はどれか」を求めるのが逆引きです。aigile では当面、**インデックスファイルを持たず、grep で都度計算** します:

```sh
grep -rln 'id: "req:sso-login"' .aigile/docs/L2_specifications/ .aigile/docs/L3_architectures/
```

将来 Document 数が増えてパフォーマンスや一括解析が問題になれば `.aigile/docs/index.json` を CI または gh-aw で生成する形に拡張可能ですが、初期は不要です。

## 影響範囲分析の 3 帯域

Requirement Document に変更が入った際の影響範囲は、後段の `aigile-impact-analyzer` ワークフローが以下の 3 帯域で分類します:

| 帯域 | 判定 | 後続アクション |
|---|---|---|
| **Green** | 高信頼度。既存の AC や振る舞いと明確に矛盾、または依存先の中核フィールドが変更された | 自動で Spec/Arch 更新 PR を発行 |
| **Amber** | 中信頼度。関連はあるが矛盾が曖昧で、人間判断が必要 | Issue コメントで関係者に確認を投げる |
| **Gray** | 低信頼度。依存先が動いたが本文に内容変更が不要な可能性が高い | ログのみ。アクションは取らない |

ワークフロー本体の実装は `.github/workflows/aigile-impact-analyzer.md` に置きます（本リポジトリ内では今後の Step で実装）。

## frontmatter の例

### Requirement

```yaml
---
node_id: "req:sso-login"
layer: requirement
last_updated: 2026-05-23
source_issue: 42
---

# Requirement: SSO ログイン対応

...
```

### Specification

```yaml
---
node_id: "spec:sso-login"
layer: specification
last_updated: 2026-05-23
depends_on:
  - id: "req:sso-login"
    relation: implements
---

# Specification: SSO ログインフロー

...
```

### Architecture

```yaml
---
node_id: "arch:sso-login"
layer: architecture
last_updated: 2026-05-23
depends_on:
  - id: "spec:sso-login"
    relation: realizes
---

# Architecture: SSO ログイン基盤

...
```

## 不変条件

aigile の Document 管理規約に通底する原則:

1. **frontmatter は AI が生成・維持する** — 人間は本文の振る舞い記述に集中する。frontmatter の手書きを強制しない。
2. **`node_id` の slug 部分はファイル名と一致** — 矛盾した状態は CI で検出されエラーとして扱う（CI 実装は将来の課題）。
3. **`depends_on[].id` は実在する node を指す** — リンク切れは CI で検出する（同上）。
4. **依存方向は下位 → 上位の単方向** — 上位 Document に下位への参照フィールドを書かない。

## 関連

- レイヤーモデル: [layers.md](layers.md)
- コアコンセプト: [concepts.md](concepts.md)
- 開発ワークフロー: [workflow.md](workflow.md)