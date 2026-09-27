import SwiftUI
import PDFKitExt

struct FontPreviewView: View {
    let font: any PDFFont
    @AppStorage(Settings.previewText.key)
    private var previewText = Settings.previewText.default
    @AppStorage(Settings.previewFontSize.key)
    private var previewFontSize = Settings.previewFontSize.default
    private var systemFont: NSFont?
    // TODO: in UserDefaults
    @State private var isFontSectionExpanded = false
    private let showDetails: Bool

    var previewFont: Font? {
        systemFont.map { Font($0) }
    }

    var previewFontURL: URL? {
        systemFont.flatMap {
            CTFontCopyAttribute($0, kCTFontURLAttribute) as? URL
        }
    }

    init(font: any PDFFont, showDetails: Bool) {
        self.font = font
        self.showDetails = showDetails
        self.systemFont = FontUtil.getSystemFont(named: font.displayName, size: previewFontSize)
    }

    var body: some View {
        if showDetails {
            detailsView
        } else {
            previewView
                .padding()
        }
    }

    @ViewBuilder
    private var previewView: some View {
        Text(previewText)
            .font(previewFont)
    }

    @ViewBuilder
    private var detailsView: some View {
        Form {
            Section("Preview") {
                HStack {
                    Spacer()
                    previewView
                    Spacer()
                }
            }

            Section {
                if isFontSectionExpanded {
                    LabeledContent("Name") {
                        Text(font.displayName)
                    }
                    LabeledContent("Type") {
                        Text(FontUtil.typeString(for: font))
                    }
                    LabeledContent("Embedded") {
                        Text(font.isEmbedded ? "Yes" : "No")
                    }
                    LabeledContent("Subset") {
                        Text(font.isSubset ? "Yes" : "No")
                    }
                    LabeledContent("File") {
                        if let previewFontURL {
                            FileButton(url: previewFontURL, type: .revealFile)
                        } else {
                            Text("Not Installed")
                        }
                    }
                    if !flagString.isEmpty {
                        LabeledContent("Flags") {
                            Text(flagString)
                        }
                    }
                }
            } header: {
                Button {
                    isFontSectionExpanded.toggle()
                } label: {
                    HStack {
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(isFontSectionExpanded ? 90 : 0))
                        Text("Font")
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .formStyle(.grouped)
    }

    private var flagString: String {
        guard let flagsDict = (font as? any PDFProgramFont)?.descriptor?.flags.displayDictionary else {
            return ""
        }
        return flagsDict.compactMap { key, value in
            value ? key : nil
        }.joined(separator: ", ")
    }
}



#Preview("No Details") {
    let url = Bundle.main.url(forResource: "multi_font_mixed", withExtension: "pdf")!
    let document = PDFDocument(url: url)!

    TabView {
        ForEach(Array(document.fonts.enumerated()), id: \.offset) { i, font in
            FontPreviewView(font: document.fonts[i], showDetails: false)
                .tabItem {
                    Text("\(i)")
                }
        }
    }
}


#Preview("Details") {
    let url = Bundle.main.url(forResource: "multi_font_mixed", withExtension: "pdf")!
    let document = PDFDocument(url: url)!

    TabView {
        ForEach(Array(document.fonts.enumerated()), id: \.offset) { i, font in
            FontPreviewView(font: document.fonts[i], showDetails: true)
                .tabItem {
                    Text("\(i)")
                }
        }
    }
}

