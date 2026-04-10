# freee API スキル

freee MCPを使って、会計・人事労務・請求書・工数管理・販売管理のAPIをAIから直接操作します。

## 接続方法

Remote MCPを使用（`https://mcp.freee.co.jp/mcp`）。認証が必要な場合は `authenticate` ツールを呼び出してください。

## 利用可能なツール

### 認証・事業所管理
- `authenticate` - freeeにOAuth認証でログイン
- `auth_status` - 認証状態の確認
- `clear_auth` - 認証情報のクリア
- `list_companies` - 事業所一覧の取得
- `set_current_company` - 操作対象の事業所を切り替え
- `file_upload` - ファイルのアップロード

### APIリクエスト
- `freee_api_get` - GETリクエスト
- `freee_api_post` - POSTリクエスト
- `freee_api_put` - PUTリクエスト
- `freee_api_patch` - PATCHリクエスト
- `freee_api_delete` - DELETEリクエスト

## 対応サービス

| サービス | 内容 |
|---------|------|
| accounting | 取引・勘定科目・仕訳管理 |
| hr | 従業員・給与・勤怠データ |
| invoice | 請求書・見積書 |
| pm | プロジェクト・工数管理 |
| sm | 販売管理 |

## 推奨ワークフロー

1. `auth_status` で認証状態を確認
2. 未認証なら `authenticate` でログイン
3. `list_companies` で事業所を確認し `set_current_company` で切り替え
4. 目的のAPIを呼び出す

## 使用例

```
# 取引一覧を取得する
freee_api_get("accounting/deals", { company_id: <事業所ID> })

# 請求書を作成する
freee_api_post("invoices/invoices", { company_id: <事業所ID>, ... })
```
