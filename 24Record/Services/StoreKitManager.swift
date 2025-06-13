import StoreKit
import SwiftUI

@MainActor
final class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    // Product IDs
    private let productIds = ["com.24record.premium.monthly"]
    private let monthlyProductId = "com.24record.premium.monthly"
    
    // Published properties
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs = Set<String>()
    @Published private(set) var isPremium = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    // Transaction listener task
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        startTransactionListener()
        Task {
            await loadProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            products = try await Product.products(for: productIds)
            isLoading = false
        } catch {
            print("Failed product request from App Store server: \(error)")
            errorMessage = "商品の読み込みに失敗しました"
            isLoading = false
        }
    }
    
    // MARK: - Purchase
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateCustomerProductStatus()
            await transaction.finish()
            return transaction
            
        case .userCancelled:
            return nil
            
        case .pending:
            return nil
            
        @unknown default:
            return nil
        }
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async {
        isLoading = true
        
        do {
            try await AppStore.sync()
            await updateCustomerProductStatus()
            isLoading = false
        } catch {
            print("Failed to restore purchases: \(error)")
            errorMessage = "購入の復元に失敗しました"
            isLoading = false
        }
    }
    
    // MARK: - Transaction Updates
    private func startTransactionListener() {
        updateListenerTask = Task.detached {
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }
    
    @MainActor
    private func updateCustomerProductStatus() async {
        var purchasedProducts = Set<String>()
        
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                switch transaction.productType {
                case .autoRenewable:
                    if transaction.revocationDate == nil {
                        purchasedProducts.insert(transaction.productID)
                    }
                default:
                    break
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
        
        self.purchasedProductIDs = purchasedProducts
        self.isPremium = purchasedProducts.contains(monthlyProductId)
        
        // Save premium status to UserDefaults for quick access
        UserDefaults.standard.set(isPremium, forKey: "isPremium")
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Subscription Management
    func manageSubscriptions() async {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            do {
                try await AppStore.showManageSubscriptions(in: windowScene)
            } catch {
                print("Failed to show manage subscriptions: \(error)")
                errorMessage = "サブスクリプション管理画面を開けませんでした"
            }
        }
    }
    
    // MARK: - Convenience Methods
    var monthlyProduct: Product? {
        products.first { $0.id == monthlyProductId }
    }
    
    var formattedPrice: String {
        guard let product = monthlyProduct else { return "¥480" }
        return product.displayPrice
    }
    
    // MARK: - Premium Features Check
    static var isPremium: Bool {
        #if DEBUG
        // テストモードでは常にプレミアム版として動作
        return true
        #else
        // Quick check from UserDefaults for synchronous access
        return UserDefaults.standard.bool(forKey: "isPremium")
        #endif
    }
    
    // Premium feature limits
    static let freeTaskLimit = 5 // 無料版は1日5タスクまで
    static let freeTemplateLimit = 3 // 無料版はテンプレート3個まで
}

enum StoreError: Error {
    case failedVerification
}

// MARK: - Premium Features
struct PremiumFeatures {
    static let features = [
        PremiumFeature(
            icon: "infinity",
            title: "無制限のタスク作成",
            description: "1日のタスク数に制限なし"
        ),
        PremiumFeature(
            icon: "doc.on.doc.fill",
            title: "無制限のテンプレート",
            description: "テンプレートを好きなだけ作成"
        ),
        PremiumFeature(
            icon: "chart.line.uptrend.xyaxis",
            title: "詳細な統計情報",
            description: "週間・月間の詳細分析"
        ),
        PremiumFeature(
            icon: "square.and.arrow.up",
            title: "データエクスポート",
            description: "CSVファイルでデータ出力"
        ),
        PremiumFeature(
            icon: "paintbrush.fill",
            title: "カスタムテーマ",
            description: "アプリの外観をカスタマイズ"
        ),
        PremiumFeature(
            icon: "bell.badge.fill",
            title: "高度な通知設定",
            description: "タスク開始・終了の通知"
        )
    ]
}

struct PremiumFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}