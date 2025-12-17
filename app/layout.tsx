import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Bsta スキンケア - AI肌診断・CRMシステム",
  description: "AIを活用した肌診断機能とCRMを統合した、次世代スキンケアサロン向けシステム",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ja">
      <body className="antialiased">
        {children}
      </body>
    </html>
  );
}
