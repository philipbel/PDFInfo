import SwiftUI

struct PDFDocumentInfoView: View {
    private static let formFont = Font.subheadline
    let document: PDFDocumentModel

    var body: some View {
        Form {
            Section {
                LabeledContent("File") {
                    HStack(spacing: 0) {
                        let fileString = if document.url.isFileURL {
                            document.url.relativePath
                        } else {
                            document.url.absoluteString
                        }
                        Text(fileString)
                            .truncationMode(.middle)
                            .lineLimit(1)
                            .help(fileString)
                        Button("", systemImage: "arrow.right.circle.fill") {
                            NSWorkspace.shared.open(document.url)
                        }
                        .buttonStyle(.plain)
                        .help("Open file")
                    }
                }
                .font(Self.formFont)
            }

            Section("PDF") {
                LabeledContent("PDF Version:") {
                    Text(document.version)
                }
                .font(Self.formFont)
                LabeledContent("Pages:") {
                    Text("\(document.pageCount)")
                }
                .font(Self.formFont)
                LabeledContent("Page Size:") {
                    Text(document.pageSize?.formatted() ?? "N/A")
                        .accessibilityIdentifier("page_size")
                }
                .font(Self.formFont)
            }
            if !document.metadata.isEmpty {
                Section("Metadata") {
                    ForEach(
                        document.metadata.sorted(by: { $0.key < $1.key}),
                        id: \.key
                    ) { key, value in
                        LabeledContent(key + ":") {
                            Text(document.metadata[key] ?? "N/A")
                        }
                        .font(Self.formFont)
                    }
                }
            }
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    PDFDocumentInfoView(
        document: PDFDocumentModel(
            url: URL(string: "file:///a/b/c/d.pdf")!,
            fonts: [],
            version: "2.1",
            pageCount: 3,
            pageSize: .a4,
            metadata: [
                "Author": "Einstein"
            ]
        )
    )
    .formStyle(.grouped)
}
