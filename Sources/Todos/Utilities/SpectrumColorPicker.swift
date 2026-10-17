import SwiftUI

/// Full-spectrum color picker built entirely in SwiftUI (saturation/brightness field,
/// hue strip, hex entry, and quick presets) so it never opens a separate AppKit
/// window. SwiftUI's native `ColorPicker` opens `NSColorPanel`, and — like the system
/// Character Viewer used for emoji — presenting an auxiliary AppKit panel from inside
/// `MenuBarExtra(.window)` causes the popover's non-activating panel to resign key
/// and the whole popover to dismiss before a selection can be made. Staying
/// self-contained avoids that entirely while still giving full (not just swatch-
/// limited) color choice.
struct SpectrumColorPickerView: View {
    @Binding var selectedHex: String?

    final class ViewState: ObservableObject {
        @Published var hue: Double = 0.58
        @Published var saturation: Double = 0.65
        @Published var brightness: Double = 0.85
        @Published var hexText: String = ""
    }

    @StateObject private var vs = ViewState()

    private var currentColor: Color {
        Color(hue: vs.hue, saturation: vs.saturation, brightness: vs.brightness)
    }

    private var hueSpectrum: [Color] {
        stride(from: 0.0, through: 1.0, by: 1.0 / 12).map { Color(hue: $0, saturation: 1, brightness: 1) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Quick presets
            HStack(spacing: 6) {
                Button {
                    selectedHex = nil
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(nsColor: .windowBackgroundColor))
                            .frame(width: 20, height: 20)
                            .overlay(Circle().stroke(Color.secondary.opacity(0.4), lineWidth: 1))
                        Image(systemName: "nosign").font(.system(size: 9)).foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .help("No color")

                ForEach(AppPalette.colors, id: \.hex) { entry in
                    Button {
                        apply(hex: entry.hex)
                    } label: {
                        Circle().fill(Color(hex: entry.hex) ?? .clear).frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                    .help(entry.name)
                }
            }

            // Saturation / brightness field, tinted by the current hue
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hue: vs.hue, saturation: 1, brightness: 1))
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            colors: [.white, .white.opacity(0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            colors: [.black.opacity(0), .black],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                    selectionDot(color: currentColor)
                        .position(
                            x: vs.saturation * geo.size.width,
                            y: (1 - vs.brightness) * geo.size.height
                        )
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            vs.saturation = clampedFraction(value.location.x, total: geo.size.width)
                            vs.brightness = 1 - clampedFraction(value.location.y, total: geo.size.height)
                            commit()
                        }
                )
            }
            .frame(height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Hue strip
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    Capsule().fill(LinearGradient(
                        colors: hueSpectrum, startPoint: .leading, endPoint: .trailing
                    ))
                    selectionDot(color: Color(hue: vs.hue, saturation: 1, brightness: 1))
                        .position(x: vs.hue * geo.size.width, y: geo.size.height / 2)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            vs.hue = clampedFraction(value.location.x, total: geo.size.width)
                            commit()
                        }
                )
            }
            .frame(height: 14)

            // Hex entry + live preview
            HStack(spacing: 8) {
                Circle()
                    .fill(selectedHex.flatMap { Color(hex: $0) } ?? Color.clear)
                    .frame(width: 22, height: 22)
                    .overlay(Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 1))

                TextField("#RRGGBB", text: $vs.hexText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(width: 90)
                    .onSubmit { applyTypedHex() }
                    .onChange(of: vs.hexText) { _, _ in applyTypedHex() }

                Spacer()
            }
        }
        .onAppear { syncFromSelection() }
    }

    @ViewBuilder
    private func selectionDot(color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 14, height: 14)
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .shadow(color: .black.opacity(0.3), radius: 1)
    }

    private func clampedFraction(_ value: CGFloat, total: CGFloat) -> Double {
        guard total > 0 else { return 0 }
        return Double(min(max(value, 0), total) / total)
    }

    private func commit() {
        let hex = currentColor.toHex()
        selectedHex = hex
        vs.hexText = hex ?? ""
    }

    private func apply(hex: String) {
        selectedHex = hex
        syncFromSelection()
    }

    private func applyTypedHex() {
        let trimmed = vs.hexText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let color = Color(hex: trimmed) else { return }
        selectedHex = trimmed.hasPrefix("#") ? trimmed : "#\(trimmed)"
        if let hsb = color.hsb() {
            vs.hue = hsb.hue
            vs.saturation = hsb.saturation
            vs.brightness = hsb.brightness
        }
    }

    private func syncFromSelection() {
        guard let hex = selectedHex, let color = Color(hex: hex) else {
            vs.hexText = selectedHex ?? ""
            return
        }
        vs.hexText = hex
        if let hsb = color.hsb() {
            vs.hue = hsb.hue
            vs.saturation = hsb.saturation
            vs.brightness = hsb.brightness
        }
    }
}
