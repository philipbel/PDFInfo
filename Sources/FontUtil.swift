import AppKit
import Foundation


struct FontUtil {
    static func getSystemFont(named name: String, size: CGFloat) -> NSFont? {
        // 1. As given: PostScript name or family
        if let f = NSFont(name: name, size: size) {
            return f
        }

        // TODO: Other suffixes to support? Encountered this with IBM Plex fonts.
        // 2. "<Family> Regular", drop the Regular part
        if name.hasSuffix(" Regular") {
            let family = String(name.dropLast(" Regular".count))
            if let f = NSFont(name: family, size: size) {
                return f
            }
            // 3. family name only, resolve to a concrete member via descriptor
            let desc = NSFontDescriptor(fontAttributes: [.family: family])
            if let f = NSFont(descriptor: desc, size: size) {
                return f
            }
        }
        return nil
    }
}
