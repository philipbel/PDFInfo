import SwiftUI



struct DocumentInspectorView: View {
    static let formFont = Font.subheadline
    let document: PDFDocumentModel

    var body: some View {
        Form {
            DocumentAttributesView(document: document)
            DocumentKeywordsView(keywords: document.metadata.keywords)
        }
        .formStyle(.grouped)

    }

    init(document: PDFDocumentModel) {
        self.document = document
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    DocumentInspectorView(
        document: PDFDocumentModel(
            url: URL(string: "file:///a/b/c/d.pdf")!,
            fonts: [],
            version: "2.1",
            pageCount: 3,
            pageSize: .a4,
            metadata: .init(author: "Einstein",
                            keywords: [
                                "foo", "bar", "baz"
                            ])
        )
    )
    .formStyle(.grouped)
}
