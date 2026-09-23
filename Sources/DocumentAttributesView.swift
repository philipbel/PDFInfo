import SwiftUI

struct DocumentAttributesView: View {
    let document: PDFDocumentModel
    let metadata: [(String, String?)]

    var body: some View {
        Section {
            LabeledContent("File") {
                HStack(spacing: 0) {
                    let fileString = document.url.lastPathComponent
                    let fileHelpString = if document.url.isFileURL {
                        document.url.relativePath
                    } else {
                        document.url.absoluteString
                    }
                    Text(fileString)
                        .truncationMode(.middle)
                        .lineLimit(1)
                        .help(fileHelpString)
                    Button("", systemImage: "arrow.right.circle.fill") {
                        NSWorkspace.shared.open(document.url)
                    }
                    .buttonStyle(.plain)
                    .help("Open \(fileHelpString)")
                }
            }
            .font(DocumentInspectorView.formFont)
        }

        Section() {
            LabeledContent("PDF Version:") {
                Text(document.version)
            }
            .font(DocumentInspectorView.formFont)
            LabeledContent("Page Count:") {
                Text("\(document.pageCount)")
            }
            .font(DocumentInspectorView.formFont)
            LabeledContent("Page Size:") {
                Text(document.pageSize?.formatted() ?? "N/A")
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

    init(document: PDFDocumentModel) {
        self.document = document
        metadata = [
            ("Author", document.metadata.author),
            ("Title", document.metadata.title),
            ("Subject", document.metadata.subject),
            ("Creator", document.metadata.creator),
            ("Producer", document.metadata.producer),
            ("Creation Date", document.metadata.creationDate?.formatted()),
            ("Modification Date", document.metadata.modificationDate?.formatted()),
        ]
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    DocumentAttributesView(
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
}
