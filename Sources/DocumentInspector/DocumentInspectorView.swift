import SwiftUI
import PDFKitExt


struct DocumentInspectorView: View {
    static let formFont = Font.subheadline

    let document: PDFDocument
    let url: URL

    var body: some View {
        Form {
            DocumentAttributesView(document: document, url: url)
            DocumentKeywordsView(keywords: document.metadata.keywords)
        }
        .formStyle(.grouped)

    }

    init(document: PDFDocument, url: URL) {
        self.document = document
        self.url = url
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    let url = Bundle.main.url(forResource: "multi_font_mixed", withExtension: "pdf")!
    let document = PDFDocument(url: url)!

    DocumentInspectorView(document: document, url: url)
        .formStyle(.grouped)
}
