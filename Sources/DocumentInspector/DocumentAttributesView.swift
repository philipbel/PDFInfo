import SwiftUI
import PDFKitExt

struct DocumentAttributesView: View {
    let url: URL
    let document: PDFDocument
    let metadata: [(String, String?)]

    var body: some View {
        Section {
            LabeledContent("File:") {
                FileButton(url: url, type: .openFile)
            }
            .font(DocumentInspectorView.formFont)
        }

        Section {
            LabeledContent("PDF Version:") {
                Text(document.version)
            }
            .font(DocumentInspectorView.formFont)
            LabeledContent("Page Count:") {
                Text(String("\(document.pageCount)"))
            }
            .font(DocumentInspectorView.formFont)
            LabeledContent("Page Size:") {
                Text(document.pageSize?.formatted() ?? String(localized: "N/A"))
                    .accessibilityIdentifier("page_size")
            }
            .font(DocumentInspectorView.formFont)
        }

        Section {
            ForEach(metadata, id: \.0) { key, value in
                if let value {
                    LabeledContent(key, value: value)
                        .font(DocumentInspectorView.formFont)
                }
            }
        }
    }

    init(document: PDFDocument, url: URL) {
        self.url = url
        self.document = document
        metadata = [
            (String(localized: "Author:"), document.metadata.author),
            (String(localized: "Title:"), document.metadata.title),
            (String(localized: "Subject:"), document.metadata.subject),
            (String(localized: "Creator:"), document.metadata.creator),
            (String(localized: "Producer:"), document.metadata.producer),
            (String(localized: "Creation Date:"), document.metadata.creationDate?.formatted()),
            (String(localized: "Modification Date:"), document.metadata.modificationDate?.formatted()),
        ]
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    let url = Bundle.main.url(forResource: "multi_font_mixed", withExtension: "pdf")!
    let document = PDFDocument(url: url)!

    DocumentAttributesView(document: document, url: url)
}
