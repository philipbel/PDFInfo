
import SwiftUI

struct FileButton: View {
    enum FileButtonType {
        case openFile
        case revealFile
    }

    let url: URL
    let type: FileButtonType

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            let fileString = url.lastPathComponent
            let path = if url.isFileURL {
                url.relativePath
            } else {
                url.absoluteString
            }
            Text(fileString)
                .truncationMode(.middle)
                .lineLimit(1)
                .help(path)
            Button {
                action(url: url)
            } label: {
                switch type {
                case .openFile:
                    Image(systemName: "arrow.right.circle.fill")
                case .revealFile:
                    Image(systemName: "magnifyingglass.circle.fill")
                }
            }
            .buttonStyle(.plain)
            .help(helpString(path: path))
        }
    }

    private func action(url: URL) {
        switch type {
        case .openFile:
            NSWorkspace.shared.open(url)
        case .revealFile:
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    private func helpString(path: String) -> String {
        switch type {
        case .openFile:
            "Open \(path)"
        case .revealFile:
            "Reveal \(path) in Finder"
        }
    }
}

#Preview {
    FileButton(url: URL(string: "file:///System/Library/Fonts/Helvetica.ttc")!, type: .revealFile)
}

#Preview("Form") {
    Form {
        LabeledContent("Preview") {
            FileButton(url: URL(string: "file:///System/Library/Fonts/Helvetica.ttc")!, type: .revealFile)
        }
    }
    .formStyle(.grouped)
}
