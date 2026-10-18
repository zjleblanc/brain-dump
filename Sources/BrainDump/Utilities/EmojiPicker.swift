import SwiftUI

// MARK: - Emoji palette

/// Effectively "all emoji" — every Unicode scalar that defaults to emoji
/// presentation, computed once from Unicode scalar properties rather than a
/// hand-maintained list. This intentionally excludes multi-scalar sequences (flags,
/// skin-tone modifiers, ZWJ family emoji) to keep things simple, but still covers
/// the vast majority of single-glyph emoji (currently ~1,400+).
///
/// Built entirely in-app (no system Character Viewer): invoking
/// `NSApp.orderFrontCharacterPalette` from inside `MenuBarExtra(.window)` causes the
/// panel to resign key and the whole popover to dismiss before a selection can be
/// made, so a native-feeling in-app grid (mirroring `PalettePickerView`) is used
/// instead.
enum AppEmojiPalette {
    static let emojis: [String] = {
        var result: [String] = []
        result.reserveCapacity(1600)
        for value in 0x1...0x10FFFF {
            guard let scalar = Unicode.Scalar(value) else { continue }
            if scalar.properties.isEmojiPresentation {
                result.append(String(scalar))
            }
        }
        return result
    }()
}

// MARK: - Emoji picker

struct EmojiPickerView: View {
    @Binding var selectedEmoji: String?

    private let columns = [GridItem(.adaptive(minimum: 26), spacing: 6)]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 6) {
                    // "no emoji" swatch
                    Button {
                        selectedEmoji = nil
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(nsColor: .windowBackgroundColor))
                                .frame(width: 24, height: 24)
                                .overlay(Circle().stroke(Color.secondary.opacity(0.4), lineWidth: 1))
                            Image(systemName: "nosign")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    ForEach(AppEmojiPalette.emojis, id: \.self) { emoji in
                        Button {
                            selectedEmoji = emoji
                        } label: {
                            Text(emoji)
                                .font(.system(size: 15))
                                .frame(width: 24, height: 24)
                                .background {
                                    if selectedEmoji == emoji {
                                        Circle().fill(Color.accentColor.opacity(0.18))
                                    }
                                }
                                .overlay {
                                    if selectedEmoji == emoji {
                                        Circle().stroke(Color.accentColor, lineWidth: 1.5)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
            }
            .frame(height: 220)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .controlBackgroundColor)))

            Text("\(AppEmojiPalette.emojis.count) emoji available")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}
