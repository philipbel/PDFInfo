import Cocoa

class FontTableView: NSTableView {
    override func keyDown(with event: NSEvent) {
        // Space = " " (0x31 keycode, or characters == " ")
        if event.charactersIgnoringModifiers == " " {
            quickLook(with: event) // route to the responder method
        } else {
            super.keyDown(with: event)
        }
    }
}
