import SwiftUI
import PDFKitExt


@Observable
fileprivate final class FontPreviewViewModel {
    let pdfFont: any PDFFont
    private(set) var isSystemFont: Bool = false
    private(set) var previewFont: Font? = nil
    private(set) var previewFontURL: URL? = nil
    let typeString: String
    let flagString: String
    private(set) var previewText = Settings.previewText.default
    private(set) var previewFontSize = Settings.previewFontSize.default
    @ObservationIgnored
    private var previewTextObservation: NSKeyValueObservation? = nil
    @ObservationIgnored
    private var previewFontSizeObservation: NSKeyValueObservation? = nil

    init(font pdfFont: any PDFFont) {
        self.pdfFont = pdfFont
        typeString = FontUtil.typeString(for: pdfFont)

        if let flagsDict = (pdfFont as? any PDFProgramFont)?.descriptor?.flags.displayDictionary {
            flagString = flagsDict.compactMap { key, value in
                value ? key : nil
            }.joined(separator: ", ")
        } else {
            flagString = ""
        }

        previewTextObservation = UserDefaults.standard
            .observe(\.previewText, options: [.initial, .new]) { [weak self] _, value in
            if let v = value.newValue {
                DispatchQueue.main.async {
                    self?.previewText = v
                }
            }
        }

        previewFontSizeObservation = UserDefaults.standard
            .observe(\.previewFontSize, options: [.initial, .new]) { [weak self] _, value in
            if let v = value.newValue {
                DispatchQueue.main.async {
                    self?.previewFontSize = v
                    self?.updatePreviewFont()
                }
            }
        }
    }

    private func updatePreviewFont() {
        let (isSystemFont, nsFont) = Self.buildPreviewFont(for: pdfFont, size: CGFloat(previewFontSize))
        self.isSystemFont = isSystemFont

        previewFont = if let nsFont {
            Font(nsFont)
        } else {
            nil
        }

        previewFontURL = nsFont.flatMap {
            CTFontCopyAttribute($0, kCTFontURLAttribute) as? URL
        }
    }

    private static func buildPreviewFont(for pdfFont: any PDFFont,
                                         size: CGFloat) -> (isSystemFont: Bool, previewFont: NSFont?) {
        if let systemFont = FontUtil.getSystemFont(named: pdfFont.displayName, size: size) {
            return (isSystemFont: true, previewFont: systemFont)
        }
        guard let programFont = pdfFont as? any PDFProgramFont,
              let fontData = programFont.descriptor?.program?.data else {
            return (isSystemFont: false, previewFont: nil)
        }
        guard let provider = CGDataProvider(data: fontData as CFData) else {
            return (isSystemFont: false, previewFont: nil)
        }
        guard let cgFont = CGFont(provider) else {
            return (isSystemFont: false, previewFont: nil)
        }
        let ctFont = CTFontCreateWithGraphicsFont(cgFont, size, nil, nil)
        return (isSystemFont: false, ctFont as NSFont)
    }
}


struct FontPreviewView: View {
    @State private var viewModel: FontPreviewViewModel
    @AppStorage("fontPreviewDetailsExpanded")
    private var isFontDetailsSectionExpanded = false
    private let showDetails: Bool

    init(font pdfFont: any PDFFont, showDetails: Bool) {
        _viewModel = .init(initialValue: FontPreviewViewModel(font: pdfFont))
        self.showDetails = showDetails
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
        if let previewFont = viewModel.previewFont {
            Text(viewModel.previewText)
                .font(previewFont)
        } else {
            Text("No preview available")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var previewSection: some View {
        Section {
            HStack {
                Spacer()
                previewView
                Spacer()
            }
        } header: {
            Text("Preview")
        } footer: {
            if !viewModel.isSystemFont && viewModel.previewFont != nil {
                Text("Note: Font is not installed. Preview uses the font from the PDF and may not be accurate.")
                    .font(.footnote)
            }
        }
    }

    @ViewBuilder
    private var detailsView: some View {
        Form {
            previewSection

            Section {
                if isFontDetailsSectionExpanded {
                    fontDetails
                }
            } header: {
                Button {
                    isFontDetailsSectionExpanded.toggle()
                } label: {
                    HStack {
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(isFontDetailsSectionExpanded ? 90 : 0))
                        Text("Font")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .fixedSize()
                }
                .buttonStyle(.plain)
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var fontDetails: some View {
        LabeledContent("Name") {
            Text(viewModel.pdfFont.displayName)
        }
        LabeledContent("Type") {
            Text(viewModel.typeString)
        }
        LabeledContent("Embedded") {
            Text(viewModel.pdfFont.isEmbedded ? "Yes" : "No")
        }
        LabeledContent("Subset") {
            Text(viewModel.pdfFont.isSubset ? "Yes" : "No")
        }
        LabeledContent("File") {
            if let url = viewModel.previewFontURL {
                FileButton(url: url, type: .revealFile)
            } else {
                Text("Not Installed")
            }
        }
        if !viewModel.flagString.isEmpty {
            LabeledContent("Flags") {
                Text(viewModel.flagString)
            }
        }
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

