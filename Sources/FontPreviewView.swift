import SwiftUI
import AppKit

struct FontPreviewView: View {
    @AppStorage(Settings.previewText.key)
    private var previewText = Settings.previewText.default
    @AppStorage(Settings.previewFontSize.key)
    private var previewFontSize = Settings.previewFontSize.default

    let viewModel: FontPreviewViewModel
    private var previewFont: Font? {
        if let font = viewModel.font,
           let systemFont = FontUtil.getSystemFont(named: font.name, size: previewFontSize) {
            return Font(systemFont)
        } else {
            return nil
        }
    }

    var body: some View {
        VStack {
            if let font = viewModel.font {
                if let previewFont {
                    Text(previewText)
                        .font(previewFont)
                } else {
                    ContentUnavailableView("\(font.name) is not installed", systemImage: "textformat")
                }
            } else {
                ContentUnavailableView("Select a font to preview", systemImage: "textformat")
            }
        }
        .padding()
        .frame(minWidth: 200, minHeight: 100)
    }
    }

    init(viewModel: FontPreviewViewModel) {
        self.viewModel = viewModel
    }
}


#Preview("Helvetica") {
    FontPreviewView(viewModel: FontPreviewViewModel(font: PDFFont(id: "helvetica",
                                                                  name: "Helvetica",
                                                                  subtype: "TrueType",
                                                                  embedded: true,
                                                                  subset: false)))
}

#Preview("Font not installed") {
    FontPreviewView(viewModel: FontPreviewViewModel(font: PDFFont(id: "unnknown-font",
                                                                  name: "Unknown-Font",
                                                                  subtype: "TrueType",
                                                                  embedded: true,
                                                                  subset: false)))
}

#Preview("Zapfino") {
    FontPreviewView(viewModel: FontPreviewViewModel(font: PDFFont(id: "zapfino",
                                                                  name: "Zapfino",
                                                                  subtype: "TrueType",
                                                                  embedded: true,
                                                                  subset: false)))
}
