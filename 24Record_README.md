# 24Record

24時間のタイムトラッキングアプリ

## 概要

24Recordは、1日24時間の時間の使い方を記録・分析するiOSアプリです。
シンプルで美しいUIで、日々の時間管理をサポートします。

## 主な機能

- タスクの記録と管理
- カテゴリー別の時間追跡
- 日別・週別・月別の統計表示
- ルーティンタスクの自動生成
- ダークモード対応

## プレミアムサブスクリプション

24Record Premiumは月額480円で以下の機能が利用できます：

### プレミアム機能
- **無制限のタスク作成**（無料版は1日5タスクまで）
- **無制限のテンプレート**（無料版は3個まで）
- **詳細な統計情報** - 週間・月間の詳細分析
- **データエクスポート** - CSVファイルでデータ出力
- **カスタムテーマ** - アプリの外観をカスタマイズ
- **高度な通知設定** - タスク開始・終了の通知

## 開発環境

- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+
- SwiftUI
- SwiftData

## セットアップ

### 1. プロジェクトのクローン
```bash
git clone [repository-url]
cd 24Record
```

### 2. Xcodeで開く
```bash
open 24Record.xcodeproj
```

### 3. サブスクリプションのテスト設定

1. Xcodeでプロジェクトを開く
2. スキームを編集（Product > Scheme > Edit Scheme）
3. Run > Options > StoreKit Configurationで`24Record/StoreKit/Configuration.storekit`を選択
4. サンドボックステスターアカウントでテスト

詳細な設定手順は`24Record/Docs/PremiumSubscriptionSetup.md`を参照してください。

## アーキテクチャ

### ディレクトリ構造
```
24Record/
├── Models/          # データモデル（SwiftData）
├── Views/           # SwiftUIビュー
│   ├── Modern/      # メインUI
│   └── Premium/     # サブスクリプション関連
├── ViewModels/      # ビューモデル
├── Services/        # ビジネスロジック
│   └── StoreKitManager.swift  # 課金管理
└── StoreKit/        # StoreKit設定
```

### 主要コンポーネント
- **SwiftData**: データ永続化
- **StoreKit 2**: アプリ内課金
- **SwiftUI**: UI構築

## 開発ガイドライン

### コーディング規約
- SwiftUIのベストプラクティスに従う
- MVVMパターンを採用
- @MainActorを適切に使用

### Git コミット規約
- feat: 新機能
- fix: バグ修正
- docs: ドキュメント
- style: コードスタイル
- refactor: リファクタリング

## ライセンス

[ライセンス情報を追加]

## サポート

問題や質問がある場合は、Issueを作成してください。