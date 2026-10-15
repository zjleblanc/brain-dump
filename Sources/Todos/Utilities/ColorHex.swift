import SwiftUI

// MARK: - Palette

struct AppPalette {
    static let colors: [(name: String, hex: String)] = [
        ("Red",    "#FF453A"),
        ("Orange", "#FF9F0A"),
        ("Yellow", "#FFD60A"),
        ("Green",  "#30D158"),
        ("Teal",   "#40C8E0"),
        ("Blue",   "#0A84FF"),
        ("Indigo", "#5E5CE6"),
        ("Purple", "#BF5AF2"),
        ("Pink",   "#FF375F"),
        ("Gray",   "#8E8E93"),
    ]
}

// MARK: - Color <-> Hex

extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        let len = s.count
        guard len == 6 || len == 8 else { return nil }
        var value: UInt64 = 0
        guard Scanner(string: s).scanHexInt64(&value) else { return nil }
        let r, g, b, a: Double
        if len == 6 {
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >>  8) & 0xFF) / 255
            b = Double((value      ) & 0xFF) / 255
            a = 1.0
        } else {
            r = Double((value >> 24) & 0xFF) / 255
            g = Double((value >> 16) & 0xFF) / 255
            b = Double((value >>  8) & 0xFF) / 255
            a = Double((value      ) & 0xFF) / 255
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
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
