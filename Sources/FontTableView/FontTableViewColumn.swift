import Cocoa


enum FontTableViewColumn: String, CaseIterable {
    case nameColumn
    case typeColumn
    case subsetColumn
    case embeddedColumn
    case installedColumn

    var title: String {
        switch self {
        case .nameColumn:
            String(localized: "Name")
        case .typeColumn:
            String(localized: "Type")
        case .subsetColumn:
            String(localized: "Subset")
        case .embeddedColumn:
            String(localized: "Embedded")
        case .installedColumn:
            String(localized: "Installed")
        }
    }

    var key: String {
        self.rawValue
    }

    var identifier: NSUserInterfaceItemIdentifier {
        NSUserInterfaceItemIdentifier(key)
    }

    init?(identifier: NSUserInterfaceItemIdentifier) {
        self.init(rawValue: identifier.rawValue)
    }
}
