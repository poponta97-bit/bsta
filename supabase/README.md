# Supabase データベースセットアップ

## マイグレーションの適用方法

### 方法1: Supabaseダッシュボードから実行（推奨）

1. [Supabase Dashboard](https://supabase.com/dashboard/project/eyjmselbbotwzahduuhj) にアクセス
2. 左サイドバーから「SQL Editor」を選択
3. 「New Query」をクリック
4. 以下の順序でSQLファイルの内容をコピー&ペーストして実行：
   - `migrations/20250101000000_initial_schema.sql` - テーブル作成
   - `migrations/20250101000001_rls_policies.sql` - RLSポリシー設定

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

### 主要テーブル

#### ユーザー・組織管理
- `profiles` - ユーザープロフィール（auth.usersを拡張）
- `distributors` - 代理店
- `salons` - サロン
- `customers` - 顧客

#### 商品・サービス
- `products` - 商品マスタ
- `salon_menus` - 施術メニュー

#### 肌診断・施術
- `skin_diagnoses` - 肌診断データ
- `treatment_records` - 施術カルテ
- `purchase_history` - 購入履歴

#### アドバイス
- `skincare_advice` - スキンケアアドバイス
- `diet_advice` - 食事アドバイス
- `exercise_advice` - 運動アドバイス
- `sleep_advice` - 睡眠アドバイス

#### ナレッジ
- `knowledge_base` - ナレッジベース

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

### Row Level Security (RLS)

すべてのテーブルでRLSが有効化されており、ユーザーの役割に応じて適切なデータアクセス制御が実装されています。

#### 主要なポリシー：
- 顧客は自分のデータのみ閲覧可能
- サロンスタッフは所属サロンのデータを管理可能
- 代理店スタッフは配下サロンのデータを閲覧可能
- 管理者はすべてのデータにアクセス可能

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
