import SwiftUI
import PDFEngine


struct DocumentInspectorView: View {
    static let formFont = Font.subheadline

    let document: PDFDocument
    let url: URL

    var body: some View {
        Form {
            DocumentAttributesView(document: document, url: url)
            if let metadata = document.metadata {
                DocumentKeywordsView(keywords: metadata.keywords)
            }
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
    let data = try! Data(contentsOf: url)
    let document = PDFDocument(data: data)!

    DocumentInspectorView(document: document, url: url)
        .formStyle(.grouped)
}
