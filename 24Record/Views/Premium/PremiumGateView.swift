import SwiftUI

struct PremiumGateView: View {
    let feature: String
    let message: String
    @Binding var isPresented: Bool
    @State private var showingSubscription = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.pink.opacity(0.2), .purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.pink)
            }
            
            // Title
            Text("プレミアム機能")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Feature name
            Text(feature)
                .font(.system(.title3, design: .rounded))
                .foregroundColor(.gray)
            
            // Message
            Text(message)
                .font(.system(.body, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.gray.opacity(0.8))
                .padding(.horizontal)
            
            // Unlock button
            Button(action: {
                showingSubscription = true
            }) {
                HStack {
                    Image(systemName: "crown.fill")
                    Text("プレミアムで解放")
                }
                .font(.system(.body, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [.pink, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .pink.opacity(0.4), radius: 8, y: 4)
            }
            .padding(.horizontal)
            
            // Cancel button
            Button(action: {
                isPresented = false
            }) {
                Text("閉じる")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 0.08))
        )
        .padding()
        .sheet(isPresented: $showingSubscription) {
            PremiumSubscriptionView()
        }
    }
}

// MARK: - View Modifier
struct PremiumGateModifier: ViewModifier {
    @Binding var isPresented: Bool
    let feature: String
    let message: String
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                PremiumGateView(
                    feature: feature,
                    message: message,
                    isPresented: $isPresented
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
    }
}

extension View {
    func premiumGate(isPresented: Binding<Bool>, feature: String, message: String) -> some View {
        modifier(PremiumGateModifier(isPresented: isPresented, feature: feature, message: message))
    }
}

// MARK: - Simple Alert Style
struct PremiumAlertView: View {
    let title: String
    let message: String
    @Binding var isPresented: Bool
    let onUpgrade: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundColor(.pink)
            
            Text(title)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(message)
                .font(.system(.body, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                Button(action: {
                    isPresented = false
                }) {
                    Text("キャンセル")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Button(action: {
                    onUpgrade()
                    isPresented = false
                }) {
                    Text("アップグレード")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.1))
        )
        .padding(.horizontal, 40)
    }
}

// MARK: - Preview
#Preview("Gate View") {
    ZStack {
        Color.black
            .ignoresSafeArea()
        
        Text("Content")
            .premiumGate(
                isPresented: .constant(true),
                feature: "無制限のタスク",
                message: "無料版では1日5タスクまでです。\nプレミアムで無制限に作成できます。"
            )
    }
}

#Preview("Alert View") {
    ZStack {
        Color.black
            .ignoresSafeArea()
        
        PremiumAlertView(
            title: "タスク数の上限",
            message: "無料版では1日5タスクまでです",
            isPresented: .constant(true),
            onUpgrade: {}
        )
    }
}