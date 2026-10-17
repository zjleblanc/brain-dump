import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: TodoStore
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings").font(.headline)
                Spacer()
                Button("Done") { onDismiss() }.keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            VStack(alignment: .leading, spacing: 20) {
                settingsSection(
                    "Auto-Clear Delay",
                    caption: "How long a completed todo stays visible before it's automatically cleared."
                ) {
                    Picker("Clear after", selection: $store.settings.autoClearDelaySeconds) {
                        ForEach(AutoClearDelayOption.allCases) { option in
                            Text(option.label).tag(option.rawValue)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .onChange(of: store.settings.autoClearDelaySeconds) { _, _ in
                        store.save()
                    }
                }

                settingsSection(
                    "Cleared Todos",
                    caption: "Completed todos clear automatically. Control how long they're kept "
                        + "before being permanently deleted."
                ) {
                    Picker("Permanently delete after", selection: $store.settings.clearedRetentionDays) {
                        ForEach(RetentionOption.allCases) { option in
                            Text(option.label).tag(option.days)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .onChange(of: store.settings.clearedRetentionDays) { _, _ in
                        store.save()
                        store.purgeExpired()
                    }
                }

                settingsSection(
                    "Archived Todos",
                    caption: "Control how long items stay in the Archive before being permanently deleted."
                ) {
                    Picker("Permanently delete after", selection: $store.settings.archivedRetentionDays) {
                        ForEach(RetentionOption.allCases) { option in
                            Text(option.label).tag(option.days)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .onChange(of: store.settings.archivedRetentionDays) { _, _ in
                        store.save()
                        store.purgeExpired()
                    }
                }
            }
            .padding(16)
        }
        .frame(width: 360)
    }

    @ViewBuilder
    private func settingsSection<Content: View>(
        _ label: String,
        caption: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content()
            Text(caption)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}
