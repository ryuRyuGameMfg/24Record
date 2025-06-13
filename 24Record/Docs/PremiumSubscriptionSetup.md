# 24Record Premium サブスクリプション設定ガイド

## 概要

24Record Premiumは月額480円のサブスクリプションサービスです。ユーザーは以下のプレミアム機能にアクセスできます：

### プレミアム機能
- **無制限のタスク作成** - 無料版は1日5タスクまで
- **無制限のテンプレート** - 無料版は3個まで
- **詳細な統計情報** - 週間・月間の詳細分析
- **データエクスポート** - CSVファイルでデータ出力
- **カスタムテーマ** - アプリの外観をカスタマイズ
- **高度な通知設定** - タスク開始・終了の通知

## App Store Connect設定

### 1. App情報
1. App Store Connectにログイン
2. アプリを選択
3. 「App内課金」セクションに移動

### 2. サブスクリプショングループ作成
- グループ名: `Premium`
- 参照名: `Premium Subscription Group`

### 3. 自動更新サブスクリプション作成
- 製品ID: `com.24record.premium.monthly`
- 参照名: `Premium Monthly`
- 価格: ¥480
- 期間: 1ヶ月
- ローカライゼーション（日本語）:
  - 表示名: `24Record Premium`
  - 説明: `すべての機能を解放して時間管理をマスター`

### 4. App Store レビュー情報
- スクリーンショット: プレミアム機能画面
- レビューメモ: サブスクリプションの詳細説明

## Xcodeプロジェクト設定

### 1. Capabilities追加
1. プロジェクトターゲットを選択
2. `Signing & Capabilities`タブ
3. `+ Capability`をクリック
4. `In-App Purchase`を追加

### 2. StoreKit Configuration
1. `24Record/StoreKit/Configuration.storekit`ファイルを使用
2. スキーム編集で`StoreKit Configuration`を設定
3. テスト時はこのファイルを選択

## テスト手順

### 1. サンドボックステスト
1. App Store Connectでサンドボックステスターを作成
2. デバイスの設定からサンドボックスアカウントでログイン
3. アプリ内で購入をテスト

### 2. テストシナリオ
- [ ] 新規購入フロー
- [ ] 購入復元
- [ ] サブスクリプション管理画面
- [ ] 無料版の制限確認
- [ ] プレミアム機能のアンロック確認

## 実装詳細

### StoreKitManager
- パス: `/Services/StoreKitManager.swift`
- 責務: StoreKit 2 APIを使用した購入管理

### UI Components
1. **PremiumSubscriptionView**: 購読画面
2. **PremiumGateView**: 機能制限時の表示
3. **MainView**: ヘッダーにアップグレードボタン

### 制限の実装箇所
- `SwiftDataTimeTrackingViewModel`: 
  - `canAddTask()`: タスク数制限チェック
  - `canAddTemplate()`: テンプレート数制限チェック
- `UnifiedTaskAddView`: タスク追加時の制限チェック

## プライバシーポリシーと利用規約

以下のURLを実際のものに置き換えてください：
- 利用規約: `https://example.com/terms`
- プライバシーポリシー: `https://example.com/privacy`

## トラブルシューティング

### 商品が読み込めない
1. Bundle IDが正しいか確認
2. Product IDが一致しているか確認
3. App Store Connectで「準備完了」になっているか確認

### 購入が完了しない
1. サンドボックス環境の設定を確認
2. ネットワーク接続を確認
3. App Store Connectのステータスを確認

## リリースチェックリスト

- [ ] App Store Connectでサブスクリプション設定完了
- [ ] 利用規約・プライバシーポリシーのURL更新
- [ ] スクリーンショット準備
- [ ] レビュー用の説明文準備
- [ ] サンドボックステスト完了
- [ ] 本番環境でのテスト計画