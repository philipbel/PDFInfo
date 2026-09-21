import AppKit

final class ServiceProvider: NSObject {
    @objc func pdfInfo(_ pboard: NSPasteboard,
                       userData: String?,
                       error: AutoreleasingUnsafeMutablePointer<NSString>) {
        guard let urls = pboard.readObjects(forClasses: [NSURL.self]) as? [URL] else { return }
        for url in urls where url.isFileURL {
            // open a new document window for each PDF URL
            NSDocumentController.shared.openDocument(
                withContentsOf: url, display: true) { _, _, _ in }
        }
    }
}
