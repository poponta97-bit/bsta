import Link from 'next/link';
import { Button } from '@/components/ui/button';

export default function Home() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-50 to-white">
      <nav className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16 items-center">
            <div className="flex items-center">
              <h1 className="text-xl font-bold text-blue-600">Bsta</h1>
            </div>
            <div className="flex items-center space-x-4">
              <Link href="/auth/login">
                <Button variant="ghost">ログイン</Button>
              </Link>
              <Link href="/auth/signup">
                <Button>新規登録</Button>
              </Link>
            </div>
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
        <div className="text-center">
          <h1 className="text-4xl md:text-6xl font-bold text-gray-900 mb-6">
            Bsta スキンケア
            <br />
            <span className="text-blue-600">AI肌診断 & CRMシステム</span>
          </h1>
          <p className="text-xl text-gray-600 mb-12 max-w-3xl mx-auto">
            最新のAI技術を活用した肌診断で、お客様一人ひとりに最適なスキンケアアドバイスを提供。
            サロン運営を効率化する統合CRMシステム。
          </p>
          <div className="flex justify-center space-x-4">
            <Link href="/auth/signup">
              <Button size="lg" className="text-lg px-8 py-6">
                今すぐ始める
              </Button>
            </Link>
            <Link href="/auth/login">
              <Button size="lg" variant="outline" className="text-lg px-8 py-6">
                ログイン
              </Button>
            </Link>
          </div>
        </div>

        <div className="mt-24 grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="bg-white p-6 rounded-lg shadow-md">
            <div className="text-blue-600 text-4xl mb-4">🔬</div>
            <h3 className="text-xl font-bold mb-2">AI肌診断</h3>
            <p className="text-gray-600">
              先進的なAI技術で肌の状態を詳細に分析。水分量、油分量、毛穴、色素沈着など多角的に診断します。
            </p>
          </div>

          <div className="bg-white p-6 rounded-lg shadow-md">
            <div className="text-blue-600 text-4xl mb-4">💡</div>
            <h3 className="text-xl font-bold mb-2">パーソナライズアドバイス</h3>
            <p className="text-gray-600">
              診断結果に基づいて、スキンケア、食事、運動、睡眠まで包括的なアドバイスを提供します。
            </p>
          </div>

          <div className="bg-white p-6 rounded-lg shadow-md">
            <div className="text-blue-600 text-4xl mb-4">📊</div>
            <h3 className="text-xl font-bold mb-2">統合CRM</h3>
            <p className="text-gray-600">
              顧客管理、施術記録、購入履歴を一元管理。サロン運営を効率化し、顧客満足度を向上させます。
            </p>
          </div>
        </div>

        <div className="mt-24 bg-blue-600 text-white rounded-lg p-12 text-center">
          <h2 className="text-3xl font-bold mb-4">
            美しい肌への第一歩を、今日から始めましょう
          </h2>
          <p className="text-xl mb-8">
            無料アカウント登録で、すぐにご利用いただけます
          </p>
          <Link href="/auth/signup">
            <Button size="lg" variant="secondary" className="text-lg px-8 py-6">
              無料で始める
            </Button>
          </Link>
        </div>
      </main>

      <footer className="bg-gray-50 mt-24 py-8">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center text-gray-600">
          <p>&copy; 2025 Bsta スキンケア. All rights reserved.</p>
        </div>
      </footer>
    </div>
  );
}
