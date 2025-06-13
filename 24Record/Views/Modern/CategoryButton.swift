import SwiftUI

struct CategoryButton: View {
    let category: SDCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Icon with background
                ZStack {
                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [category.color, category.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color(white: 0.15), Color(white: 0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isSelected ? Color.clear : category.color.opacity(0.3),
                                    lineWidth: 2
                                )
                        )
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(isSelected ? .white : category.color)
                }
                .shadow(color: isSelected ? category.color.opacity(0.5) : Color.clear, radius: 6, x: 0, y: 3)
                
                // Category name
                Text(getDisplayName(for: category.name))
                    .font(.system(size: 11, design: .rounded))
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? .white : .gray)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [
                                category.color.opacity(0.2),
                                category.color.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [
                                Color(white: 0.08),
                                Color(white: 0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected ? category.color.opacity(0.5) : Color.gray.opacity(0.2),
                                lineWidth: 1.5
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getDisplayName(for categoryName: String) -> String {
        switch categoryName {
        case "メール・連絡":
            return "メール"
        case "準備・身支度":
            return "準備"
        case "スキルアップ":
            return "スキル"
        case "SNS・ネット":
            return "SNS"
        case "テレビ・動画":
            return "TV"
        default:
            return categoryName
        }
    }
}

// Preview
#Preview {
    VStack(spacing: 20) {
        CategoryButton(
            category: SDCategory(
                name: "仕事",
                colorHex: "FF6B9D",
                icon: "briefcase.fill",
                order: 0
            ),
            isSelected: true,
            action: {}
        )
        
        CategoryButton(
            category: SDCategory(
                name: "買い物",
                colorHex: "4ECDC4",
                icon: "cart.fill",
                order: 1
            ),
            isSelected: false,
            action: {}
        )
    }
    .padding()
    .background(Color.black)
}