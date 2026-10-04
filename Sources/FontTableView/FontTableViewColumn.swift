import Cocoa


struct FontTableViewColumn {
    let title: String
    let key: String

    var identifier: NSUserInterfaceItemIdentifier {
        NSUserInterfaceItemIdentifier(key)
    }

    static let nameColumn = FontTableViewColumn(title: String(localized: "Name"), key: "name")
    static let typeColumn = FontTableViewColumn(title: String(localized: "Type"), key: "type")
    static let subsetColumn = FontTableViewColumn(title: String(localized: "Subset"), key: "subset")
    static let embeddedColumn = FontTableViewColumn(title: String(localized: "Embedded"), key: "embedded")
    static let installedColumn = FontTableViewColumn(title: String(localized: "Installed"), key: "installed")

    static let allColumns: [FontTableViewColumn] = [
        .nameColumn,
        .typeColumn,
        .subsetColumn,
        .embeddedColumn,
        .installedColumn
    ]
}
