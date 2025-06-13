import SwiftUI
import StoreKit

struct PremiumSubscriptionView: View {
    @StateObject private var storeManager = StoreKitManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.black, Color(white: 0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Price card
                        priceCard
                        
                        // Features list
                        featuresSection
                        
                        // Purchase button
                        purchaseButton
                        
                        // Footer links
                        footerLinks
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("復元") {
                        Task {
                            await storeManager.restorePurchases()
                        }
                    }
                    .foregroundColor(.pink)
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("エラー", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onChange(of: storeManager.isPremium) { isPremium in
            if isPremium {
                dismiss()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Premium badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: .pink.opacity(0.5), radius: 20)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            Text("24Record Premium")
                .font(.system(.largeTitle, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("すべての機能を解放して\n時間管理をマスターしよう")
                .font(.system(.body, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Price Card
    private var priceCard: some View {
        VStack(spacing: 12) {
            if storeManager.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(height: 60)
            } else {
                Text(storeManager.formattedPrice)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("月額")
                    .font(.system(.title3, design: .rounded))
                    .foregroundColor(.gray)
                
                // Free trial badge if applicable
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("いつでもキャンセル可能")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.pink.opacity(0.2),
                            Color.purple.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.pink.opacity(0.5), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("プレミアム機能")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            ForEach(PremiumFeatures.features) { feature in
                HStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.pink.opacity(0.3), .purple.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: feature.icon)
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    // Text
                    VStack(alignment: .leading, spacing: 4) {
                        Text(feature.title)
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(feature.description)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Purchase Button
    private var purchaseButton: some View {
        Button(action: {
            Task {
                await purchaseSubscription()
            }
        }) {
            ZStack {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text("プレミアムに登録")
                            .fontWeight(.semibold)
                    }
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [.pink, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .pink.opacity(0.4), radius: 12, y: 6)
        }
        .disabled(isPurchasing || storeManager.isLoading || storeManager.products.isEmpty)
    }
    
    // MARK: - Footer Links
    private var footerLinks: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button("利用規約") {
                    openURL("https://example.com/terms") // Replace with actual URL
                }
                
                Text("•")
                    .foregroundColor(.gray)
                
                Button("プライバシーポリシー") {
                    openURL("https://example.com/privacy") // Replace with actual URL
                }
            }
            .font(.system(.caption, design: .rounded))
            .foregroundColor(.gray)
            
            Text("サブスクリプションは自動的に更新されます。\n設定アプリから管理・解約できます。")
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Helper Methods
    private func purchaseSubscription() async {
        guard let product = storeManager.monthlyProduct else { return }
        
        isPurchasing = true
        
        do {
            let transaction = try await storeManager.purchase(product)
            if transaction != nil {
                // Purchase successful
                isPurchasing = false
            } else {
                // Purchase cancelled
                isPurchasing = false
            }
        } catch {
            errorMessage = "購入処理中にエラーが発生しました"
            showingError = true
            isPurchasing = false
        }
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Preview
#Preview {
    PremiumSubscriptionView()
        .preferredColorScheme(.dark)
}