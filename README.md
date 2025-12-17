# Bsta スキンケア AI肌診断・顧客管理システム

AIを活用した肌診断機能とCRMを統合した、次世代スキンケアサロン向けシステムです。

## 技術スタック

- **フレームワーク**: Next.js 14 (App Router)
- **言語**: TypeScript
- **スタイリング**: Tailwind CSS + Shadcn/UI
- **バックエンド**: Supabase (PostgreSQL + Auth + Storage)
- **認証**: Supabase Auth
- **データベース**: PostgreSQL with Row Level Security (RLS)

## 主な機能

### 🔬 AI肌診断
- 詳細な肌分析（水分量、油分量、毛穴、色素沈着など）
- ライフスタイル要因の記録（睡眠、ストレス、運動、食事）
- 写真によるビジュアル記録
- AI分析結果の保存

### 💡 パーソナライズアドバイス
- スキンケアアドバイス
- 食事アドバイス
- 運動アドバイス
- 睡眠アドバイス
- 商品推奨

### 📊 顧客管理
- 顧客プロフィール管理
- 診断履歴の追跡
- 施術カルテ
- 購入履歴

### 🏢 組織管理
- 代理店管理
- サロン管理
- スタッフ管理
- 商品マスタ管理

## ユーザー役割

1. **customer** - 顧客
   - 自分の診断結果とアドバイスを閲覧
   - 施術履歴と購入履歴の確認

2. **salon_staff** - サロンスタッフ
   - 顧客管理
   - 肌診断の実施
   - 施術カルテの作成
   - 商品販売の記録

3. **distributor_staff** - 代理店スタッフ
   - 配下サロンの管理
   - 配下サロンのデータ閲覧

4. **admin** - 本部管理者
   - 全データへのフルアクセス
   - システム全体の管理

## セットアップ

### 前提条件

- Node.js 18.x 以上
- npm または yarn
- Supabaseアカウント

### インストール

1. リポジトリのクローン
```bash
git clone <repository-url>
cd bsta
```

2. 依存関係のインストール
```bash
npm install
```

3. 環境変数の設定

`.env.local` ファイルを作成し、以下を設定：

```env
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

4. データベースのセットアップ

`supabase/README.md` を参照して、データベースマイグレーションを実行してください。

### 開発サーバーの起動

```bash
npm run dev
```

ブラウザで [http://localhost:3000](http://localhost:3000) を開きます。

## プロジェクト構造

```
bsta/
├── app/                    # Next.js App Router
│   ├── auth/              # 認証関連ページ
│   ├── dashboard/         # ダッシュボード
│   └── page.tsx           # ランディングページ
├── components/            # Reactコンポーネント
│   └── ui/               # shadcn/ui コンポーネント
├── lib/                   # ユーティリティとヘルパー
│   ├── supabase/         # Supabaseクライアント設定
│   └── types/            # TypeScript型定義
├── supabase/             # データベース関連
│   ├── migrations/       # SQLマイグレーション
│   └── README.md         # データベースセットアップガイド
└── public/               # 静的ファイル
```

## データベース

データベースのセットアップと詳細については、`supabase/README.md` を参照してください。

主要テーブル：
- `profiles` - ユーザープロフィール
- `distributors` - 代理店
- `salons` - サロン
- `customers` - 顧客
- `skin_diagnoses` - 肌診断
- `treatment_records` - 施術カルテ
- `purchase_history` - 購入履歴
- `products` - 商品マスタ
- `salon_menus` - 施術メニュー
- `knowledge_base` - ナレッジベース
- `*_advice` - 各種アドバイステーブル

## 開発

### コードスタイル

- ESLint設定に従ってください
- TypeScriptの型安全性を維持してください
- コンポーネントは小さく、再利用可能に保ってください

### コミット規約

明確で説明的なコミットメッセージを使用してください：
- `feat:` 新機能
- `fix:` バグ修正
- `docs:` ドキュメント更新
- `style:` コードスタイルの変更
- `refactor:` リファクタリング
- `test:` テスト追加・修正
- `chore:` その他の変更

## デプロイ

### Vercel (推奨)

1. Vercelアカウントにログイン
2. リポジトリをインポート
3. 環境変数を設定
4. デプロイ

### その他のプラットフォーム

Next.jsアプリケーションとしてデプロイ可能なプラットフォームであれば、どこでもデプロイ可能です。

## ライセンス

Copyright © 2025 Bsta スキンケア. All rights reserved.

## サポート

問題が発生した場合は、GitHubのIssuesセクションで報告してください。
