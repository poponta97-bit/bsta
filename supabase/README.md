# Supabase データベースセットアップ

## マイグレーションの適用方法

### 方法1: Supabaseダッシュボードから実行（推奨）

1. [Supabase Dashboard](https://supabase.com/dashboard/project/eyjmselbbotwzahduuhj) にアクセス
2. 左サイドバーから「SQL Editor」を選択
3. 「New Query」をクリック
4. 以下の順序でSQLファイルの内容をコピー&ペーストして実行：
   - `migrations/20250101000000_complete_schema.sql` - 完全なデータベーススキーマ
   - `migrations/20250101000001_rls_and_storage.sql` - RLSポリシーとStorageバケット

### 方法2: Supabase CLIを使用

```bash
# Supabase CLIのインストール（初回のみ）
npm install -g supabase

# プロジェクトにリンク
supabase link --project-ref eyjmselbbotwzahduuhj

# マイグレーションを適用
supabase db push
```

## データベース構造

### 全テーブル一覧（22テーブル）

#### ユーザー・組織管理
- `profiles` - ユーザープロフィール（auth.usersを拡張）
- `distributors` - 代理店
- `salons` - サロン
- `customers` - 顧客
- `customer_transfer_logs` - 顧客移管ログ

#### 商品・在庫管理
- `products` - 商品マスタ
- `inventory` - 在庫管理
- `salon_menus` - 施術メニュー
- `product_usage` - 商品使用記録

#### 発注管理
- `orders` - 発注
- `order_items` - 発注明細

#### 肌診断・施術
- `skin_diagnoses` - 肌診断データ
- `diagnosis_photo_retention_policy` - 写真保管ポリシー
- `treatment_records` - 施術カルテ
- `purchase_history` - 購入履歴

#### AI アドバイス
- `skincare_advice` - スキンケアアドバイス
- `diet_advice` - 食事アドバイス
- `exercise_advice` - 運動アドバイス
- `sleep_advice` - 睡眠アドバイス

#### ナレッジベース
- `knowledge_base` - ナレッジベース
- `knowledge_versions` - ナレッジバージョン管理

#### 通知
- `line_notifications` - LINE通知

### ユーザー役割

システムは以下の4つの役割をサポートします：

1. **customer** - 顧客
   - 自分の診断結果とアドバイスを閲覧
   - 自分の施術履歴と購入履歴を閲覧

2. **salon_staff** - サロンスタッフ
   - 所属サロンの顧客管理
   - 肌診断の実施と記録
   - 施術カルテの作成・管理
   - 商品販売の記録

3. **distributor_staff** - 代理店スタッフ
   - 配下サロンの管理
   - 配下サロンのデータ閲覧
   - サロンの作成・編集

4. **admin** - 本部管理者
   - 全データへのフルアクセス
   - 代理店・サロンの管理
   - 商品マスタ管理
   - ナレッジベース管理

### 主要機能

#### 1. 自動計算トリガー
- **再購入予測**: 購入履歴から次回購入日を自動予測
- **顧客統計更新**: 来店回数、総支出額を自動集計
- **在庫自動更新**: 施術での商品使用時に在庫を自動減算

#### 2. ナレッジベースバージョニング
- 記事の変更履歴を自動保存
- 過去バージョンへの復元が可能

#### 3. 写真保管ポリシー
- サロンごとに診断写真の保管期間を設定可能
- 自動削除機能

### Row Level Security (RLS)

すべてのテーブル（22テーブル）でRLSが有効化されており、ユーザーの役割に応じて適切なデータアクセス制御が実装されています。

#### 主要なポリシー：
- **顧客（customer）**: 自分のデータのみ閲覧可能
- **サロンスタッフ（salon_staff）**: 所属サロンのデータを管理可能
- **代理店スタッフ（distributor_staff）**: 配下サロンのデータを閲覧可能
- **本部管理者（admin）**: すべてのデータにアクセス可能

### Storage バケット

5つのStorageバケットを設定：

1. **avatars** (公開)
   - ユーザーアバター画像
   - ユーザー自身が管理

2. **diagnosis-photos** (非公開)
   - 肌診断写真
   - サロンスタッフと該当顧客のみアクセス可能

3. **treatment-photos** (非公開)
   - 施術前後の写真
   - サロンスタッフと該当顧客のみアクセス可能

4. **product-images** (公開)
   - 商品画像
   - 管理者のみ管理可能

5. **knowledge-images** (公開)
   - ナレッジベース記事の画像
   - 管理者のみ管理可能

## 初期データの投入

マイグレーション適用後、テスト用の初期データを投入することをお勧めします：

```sql
-- 代理店の作成例
INSERT INTO distributors (name, code, email) VALUES
  ('株式会社サンプル代理店', 'DIST001', 'info@sample-dist.com');

-- サロンの作成例
INSERT INTO salons (distributor_id, name, code, email) VALUES
  ((SELECT id FROM distributors WHERE code = 'DIST001'),
   'サンプルサロン銀座店', 'SALON001', 'ginza@sample-salon.com');
```

## トラブルシューティング

### エラー: "extension uuid-ossp does not exist"
Supabaseでは通常、UUID拡張は自動的に有効化されています。このエラーが出た場合は、SQLエディタで以下を実行：
```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

### エラー: "role does not exist"
auth.usersテーブルはSupabase Authが管理しています。プロジェクトでAuthが有効になっていることを確認してください。
