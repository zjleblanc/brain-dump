import SwiftUI

struct TagBadgeView: View {
    let tag: Tag

    var body: some View {
        HStack(spacing: 3) {
            if let hex = tag.colorHex, let color = Color(hex: hex) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
            }
            Text(tag.name)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background {
            if let hex = tag.colorHex, let color = Color(hex: hex) {
                Capsule().fill(color.opacity(0.15))
            } else {
                Capsule().fill(Color.secondary.opacity(0.12))
            }
        }
        .foregroundStyle(
            tag.colorHex.flatMap { Color(hex: $0) }?.opacity(0.9) ?? Color.secondary
        )
    }
}
