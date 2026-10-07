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

    var toolTip: String {
        switch self {
        case .nameColumn:
            String(localized: "Name of the font")
        case .typeColumn:
            String(localized: "Type of the font")
        case .subsetColumn:
            String(localized: "Only a subset of the font is included in the document")
        case .embeddedColumn:
            String(localized: "The font is embedded in the document")
        case .installedColumn:
            String(localized: "The font is installed on your system")
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

    func sortDescriptor(ascending: Bool) -> NSSortDescriptor {
        NSSortDescriptor(key: self.rawValue, ascending: ascending)
    }
}
