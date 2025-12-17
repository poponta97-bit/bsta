import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import Link from 'next/link';

export default async function DashboardPage() {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect('/auth/login');
  }

  // Get user profile with role
  const { data: profile } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', user.id)
    .single();

  const handleSignOut = async () => {
    'use server';
    const supabase = await createClient();
    await supabase.auth.signOut();
    redirect('/auth/login');
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16 items-center">
            <div className="flex items-center">
              <h1 className="text-xl font-bold">Bsta スキンケア CRM</h1>
            </div>
            <div className="flex items-center space-x-4">
              <span className="text-sm text-gray-700">
                {profile?.full_name || user.email}
              </span>
              <span className="px-2 py-1 text-xs bg-blue-100 text-blue-800 rounded">
                {profile?.role || 'customer'}
              </span>
              <form action={handleSignOut}>
                <Button type="submit" variant="outline" size="sm">
                  ログアウト
                </Button>
              </form>
            </div>
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="px-4 py-6 sm:px-0">
          <div className="mb-6">
            <h2 className="text-2xl font-bold text-gray-900">
              ダッシュボード
            </h2>
            <p className="mt-1 text-sm text-gray-600">
              ようこそ、{profile?.full_name || user.email} さん
            </p>
          </div>

          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {profile?.role === 'salon_staff' && (
              <>
                <Card>
                  <CardHeader>
                    <CardTitle>顧客管理</CardTitle>
                    <CardDescription>
                      顧客情報の閲覧・管理
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <Link href="/customers">
                      <Button className="w-full">顧客一覧</Button>
                    </Link>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader>
                    <CardTitle>肌診断</CardTitle>
                    <CardDescription>
                      AI肌診断の実施
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <Link href="/diagnoses">
                      <Button className="w-full">診断一覧</Button>
                    </Link>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader>
                    <CardTitle>施術カルテ</CardTitle>
                    <CardDescription>
                      施術記録の管理
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <Link href="/treatments">
                      <Button className="w-full">施術一覧</Button>
                    </Link>
                  </CardContent>
                </Card>
              </>
            )}

            {profile?.role === 'customer' && (
              <>
                <Card>
                  <CardHeader>
                    <CardTitle>マイ肌診断</CardTitle>
                    <CardDescription>
                      過去の診断結果を確認
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <Link href="/my/diagnoses">
                      <Button className="w-full">診断履歴</Button>
                    </Link>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader>
                    <CardTitle>スキンケアアドバイス</CardTitle>
                    <CardDescription>
                      パーソナライズされたアドバイス
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <Link href="/my/advice">
                      <Button className="w-full">アドバイス</Button>
                    </Link>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader>
                    <CardTitle>購入履歴</CardTitle>
                    <CardDescription>
                      商品の購入履歴
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <Link href="/my/purchases">
                      <Button className="w-full">購入履歴</Button>
                    </Link>
                  </CardContent>
                </Card>
              </>
            )}

            {profile?.role === 'admin' && (
              <>
                <Card>
                  <CardHeader>
                    <CardTitle>代理店管理</CardTitle>
                    <CardDescription>
                      代理店の管理
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <Link href="/admin/distributors">
                      <Button className="w-full">代理店一覧</Button>
                    </Link>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader>
                    <CardTitle>サロン管理</CardTitle>
                    <CardDescription>
                      サロンの管理
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <Link href="/admin/salons">
                      <Button className="w-full">サロン一覧</Button>
                    </Link>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader>
                    <CardTitle>商品管理</CardTitle>
                    <CardDescription>
                      商品マスタの管理
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <Link href="/admin/products">
                      <Button className="w-full">商品一覧</Button>
                    </Link>
                  </CardContent>
                </Card>
              </>
            )}

            <Card>
              <CardHeader>
                <CardTitle>ナレッジベース</CardTitle>
                <CardDescription>
                  スキンケアの知識を学ぶ
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Link href="/knowledge">
                  <Button className="w-full">知識を探す</Button>
                </Link>
              </CardContent>
            </Card>
          </div>
        </div>
      </main>
    </div>
  );
}
