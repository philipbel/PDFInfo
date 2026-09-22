import SwiftUI

struct SettingsView: View {
    @AppStorage(Settings.previewText.key)
    private var previewText = Settings.previewText.default
    @AppStorage(Settings.previewFontSize.key)
    private var previewFontSize = Settings.previewFontSize.default

    var body: some View {
        Spacer()
        HStack {
            Spacer()
            Form {
                LabeledContent("Preview Text:") {
                    TextField("", text: $previewText)
                }
                LabeledContent("Font Size:") {
                    HStack(spacing: 4) {
                        TextField("", value: $previewFontSize, format: .number)
                            .frame(width: 50)
                        Stepper(
                            "",
                            value: $previewFontSize,
                            in: Double(Settings.previewFontSizeRange.lowerBound)...Double( Settings.previewFontSizeRange.upperBound),
                            step: 1
                        )
                            .labelsHidden()
                    }
                }
            }
            .formStyle(.columns)
            .padding()
            .frame(width: 600)
            Spacer()
        }
        Spacer()
    }
}

#Preview {
    SettingsView()
}
