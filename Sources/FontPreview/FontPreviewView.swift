import SwiftUI
import PDFKitExt


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
                .accessibilityValue(isFontDetailsSectionExpanded ? Text("Expanded") : Text("Collapsed"))
                .accessibilityHint(
                    isFontDetailsSectionExpanded ? Text("Hide the font details") : Text("Show the font details"))
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
    }

    @ViewBuilder
    private var fontDetails: some View {
        LabeledContent("Name") {
            Text(viewModel.pdfFont.displayName)
        }
        LabeledContent("Subtype") {
            Text(viewModel.subtypeString)
        }
        if let programKindString = viewModel.programKindString {
            LabeledContent("Program Kind") {
                Text(programKindString)
            }
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
            FontPreviewView(font: font, showDetails: false)
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
            FontPreviewView(font: font, showDetails: true)
                .tabItem {
                    Text("\(i)")
                }
        }
    }
}

