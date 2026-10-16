public import Foundation
private import FontLocatorCore


public struct FontInfo: Sendable {
    public let postscriptName: String
    public let path: URL

    public init?(fontNamed name: String) {
        guard let f = font_locator_find_font(name),
              let psName = font_locator_font_get_postscript_name(f),
              let postscriptName = String(validatingCString: psName),
              let p = font_locator_font_get_path(f) else {
            return nil
        }
        self.postscriptName = postscriptName
        self.path = URL(fileURLWithFileSystemRepresentation: p, isDirectory: false, relativeTo: nil)
    }
}


public enum FontLocatorManager {
    public static func initialize() {
        font_locator_init()
    }
}

