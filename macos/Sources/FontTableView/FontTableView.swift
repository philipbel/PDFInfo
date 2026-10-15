import Cocoa

class FontTableView: NSTableView {
    static let cellInset: CGFloat = 2
    static let columnHorizontalPadding: CGFloat = 18 // must be large enough for the sorting chevron in the header

    override func keyDown(with event: NSEvent) {
        // Space = " " (0x31 keycode, or characters == " ")
        if event.charactersIgnoringModifiers == " " {
            quickLook(with: event) // route to the responder method
        } else {
            super.keyDown(with: event)
        }
    }
}
