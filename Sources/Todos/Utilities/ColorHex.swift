import SwiftUI

// MARK: - Palette

struct AppPalette {
    static let colors: [(name: String, hex: String)] = [
        ("Red", "#FF453A"),
        ("Orange", "#FF9F0A"),
        ("Yellow", "#FFD60A"),
        ("Green", "#30D158"),
        ("Teal", "#40C8E0"),
        ("Blue", "#0A84FF"),
        ("Indigo", "#5E5CE6"),
        ("Purple", "#BF5AF2"),
        ("Pink", "#FF375F"),
        ("Gray", "#8E8E93")
    ]
}

// MARK: - Color <-> Hex

extension Color {
    init?(hex: String) {
        var hexStr = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexStr.hasPrefix("#") { hexStr.removeFirst() }
        let len = hexStr.count
        guard len == 6 || len == 8 else { return nil }
        var value: UInt64 = 0
        guard Scanner(string: hexStr).scanHexInt64(&value) else { return nil }
        let red, green, blue, alpha: Double
        if len == 6 {
            red   = Double((value >> 16) & 0xFF) / 255
            green = Double((value >> 8) & 0xFF) / 255
            blue  = Double(value & 0xFF) / 255
            alpha = 1.0
        } else {
            red   = Double((value >> 24) & 0xFF) / 255
            green = Double((value >> 16) & 0xFF) / 255
            blue  = Double((value >> 8) & 0xFF) / 255
            alpha = Double(value & 0xFF) / 255
        }
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

// MARK: - Palette picker

struct PalettePickerView: View {
    @Binding var selectedHex: String?

    private let columns = [GridItem(.adaptive(minimum: 24), spacing: 6)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            // "no color" swatch
            Button {
                selectedHex = nil
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(nsColor: .windowBackgroundColor))
                        .frame(width: 22, height: 22)
                        .overlay(Circle().stroke(Color.secondary.opacity(0.4), lineWidth: 1))
                    Image(systemName: "nosign")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            ForEach(AppPalette.colors, id: \.hex) { entry in
                Button {
                    selectedHex = entry.hex
                } label: {
                    Circle()
                        .fill(Color(hex: entry.hex) ?? .clear)
                        .frame(width: 22, height: 22)
                        .overlay {
                            if selectedHex == entry.hex {
                                Circle().stroke(Color.white, lineWidth: 2)
                                Circle().stroke(Color(hex: entry.hex) ?? .clear, lineWidth: 3.5)
                            }
                        }
                }
                .buttonStyle(.plain)
                .help(entry.name)
            }
        }
        .padding(4)
    }
}
