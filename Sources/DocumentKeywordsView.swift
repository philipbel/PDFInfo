import SwiftUI


fileprivate struct KeywordLabeledContentStyle: LabeledContentStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.content
            .font(DocumentInspectorView.formFont)
    }
}

struct DocumentKeywordsView: View {
    let keywords: [String]

    var body: some View {
        Section("Keywords") {
            ForEach(keywords, id: \.self) { keyword in
                LabeledContent("") {
                    TextField("", text: .constant(keyword))
                        .font(DocumentInspectorView.formFont)
                }
                .labelsHidden()
                .labeledContentStyle(KeywordLabeledContentStyle())
            }
        }
    }
}

#Preview {
    DocumentKeywordsView(keywords: [
        "foo", "goo", "bar", "baz"
    ])
}
