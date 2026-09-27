import Cocoa


struct FontTableViewColumn {
    let title: String
    let key: String

    var identifier: NSUserInterfaceItemIdentifier {
        NSUserInterfaceItemIdentifier(key)
    }

    static let nameColumn = FontTableViewColumn(title: "Name", key: "name")
    static let typeColumn = FontTableViewColumn(title: "Type", key: "type")
    static let subsetColumn = FontTableViewColumn(title: "Subset", key: "subset")
    static let embeddedColumn = FontTableViewColumn(title: "Embedded", key: "embedded")
    static let installedColumn = FontTableViewColumn(title: "Installed", key: "installed")

    static let allColumns: [FontTableViewColumn] = [
        .nameColumn,
        .typeColumn,
        .subsetColumn,
        .embeddedColumn,
        .installedColumn
    ]
}
