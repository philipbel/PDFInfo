// Copyright (c) 2026 Philip B. (philipbel)
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

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
        if !keywords.isEmpty {
            Section("Keywords") {
                ForEach(keywords, id: \.self) { keyword in
                    LabeledContent("") {
                        TextField("", text: .constant(keyword))
                            .font(DocumentInspectorView.formFont)
                            .textSelection(.enabled)
                    }
                    .labelsHidden()
                    .labeledContentStyle(KeywordLabeledContentStyle())
                }
            }
        }
    }
}

#Preview {
    Form {
        DocumentKeywordsView(keywords: [
            "foo", "goo", "bar", "baz"
        ])
    }.formStyle(.grouped)
}
