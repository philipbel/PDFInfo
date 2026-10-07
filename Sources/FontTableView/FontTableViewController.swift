import AppKit
import PDFKitExt
import OSLog


final class FontTableViewController: NSViewController {
    private static let logger = Logger(subsystem: "PDFInfo", category: className())

    private static let nameColumnMinWidth: CGFloat = 50

    private var fonts: [any PDFFont] = []
    private var systemAvailableFonts: Set<String> = Set()
    private let tableView = FontTableView()
    private var previewPopover: NSPopover?

    var onDoubleClick: ((any PDFFont) -> Void)?

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    override func loadView() {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.documentView = tableView
        scrollView.autohidesScrollers = true

        configureColumns()
        tableView.autosaveName = "font-table-view"
        tableView.dataSource = self
        tableView.delegate = self
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsColumnResizing = true
        tableView.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle
        tableView.target = self // Selector target
        tableView.doubleAction = #selector(handleDoubleClick)
        tableView.setAccessibilityIdentifier("fonts-table")
        tableView.sortDescriptors = [PDFFontSortDescriptor(key: FontTableViewColumn.nameColumn.key, ascending: true)]

        self.view = scrollView
    }

    override func quickLook(with event: NSEvent) {
        if let existingPopover = previewPopover, existingPopover.isShown {
            existingPopover.close()
            previewPopover = nil
        } else {
            let row = tableView.selectedRow
            showPreviewPopover(for: row)
        }
    }

    private func showPreviewPopover(for row: Int) {
        guard row >= 0, row < fonts.count else {
            previewPopover?.close()
            previewPopover = nil
            return
        }
        let font = fonts[row]
        let nameColumnIndex = tableView.column(withIdentifier: FontTableViewColumn.nameColumn.identifier)
        let anchorRect = tableView.frameOfCell(atColumn: nameColumnIndex, row: row)

        previewPopover?.close()

        let popover = NSPopover()
        popover.behavior = .transient // dismiss on click-away / Escape
        popover.contentViewController = FontQuickLookViewController(font: font)
        popover.show(relativeTo: anchorRect, of: tableView, preferredEdge: .maxY)
        previewPopover = popover
    }

    private func configureColumns() {
        for column in FontTableViewColumn.allCases {
            let tableColumn = NSTableColumn(identifier: column.identifier)
            tableColumn.title = column.title
            tableColumn.sortDescriptorPrototype = PDFFontSortDescriptor(
                key: column.key,
                ascending: true,
                systemAvailableFonts: systemAvailableFonts
            )
            tableView.addTableColumn(tableColumn)
        }
    }

    private func sizeColumnsToFit() {
        let cellFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let attrs = [NSAttributedString.Key.font: cellFont]

        let padding = 4 * FontTableView.cellInset
        for column in tableView.tableColumns {
            switch column.identifier {
            case FontTableViewColumn.nameColumn.identifier:
                column.minWidth = Self.nameColumnMinWidth + padding
                column.maxWidth = .infinity
            case FontTableViewColumn.subsetColumn.identifier,
                FontTableViewColumn.embeddedColumn.identifier,
                FontTableViewColumn.installedColumn.identifier:
                column.minWidth = headerWidth(for: column) + padding
                column.width = column.minWidth
                column.maxWidth = column.minWidth
            default:
                let maxWidth = columnValues(for: column).reduce(headerWidth(for: column)) { partialResult, value in
                    max(partialResult, (value as NSString).size(withAttributes: attrs).width)
                }
                column.width = maxWidth + padding
                column.minWidth = maxWidth + padding
            }
        }
    }

    private func columnValues(for column: NSTableColumn) -> [String] {
        if let c = FontTableViewColumn(identifier: column.identifier),
           c == .typeColumn {
            return fonts.map(FontUtil.typeString(for:))
        } else {
            // the other columns are checkboxes
            return []
        }
    }

    private func headerWidth(for column: NSTableColumn) -> CGFloat {
        let attrs = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: NSFont.systemFontSize)]
        return (column.title as NSString).size(withAttributes: attrs).width
    }

    func update(fonts: [any PDFFont]) {
        previewPopover?.close()

        // New fonts
        self.fonts = fonts
        updateSystemAvailableFonts()
        // Update the prototype font descriptors in each of the table view's columns
        for column in tableView.tableColumns {
            guard let c = FontTableViewColumn(identifier: column.identifier) else {
                continue
            }
            column.sortDescriptorPrototype = PDFFontSortDescriptor(
                key: c.key,
                ascending: true,
                systemAvailableFonts: systemAvailableFonts
            )
        }
        // Update the font descriptors in the table view
        rebuildFontDescriptors()
        // Now sort
        sort()
        // Only then reload
        tableView.reloadData()
        // Column sizing after the data has been reloaded
        if !tableView.autosaveTableColumns {
            // On first run, first resize the columns based on the data
            sizeColumnsToFit()
            // Now load the user's preferences, if any
            tableView.autosaveTableColumns = true
        }
    }

    private func rebuildFontDescriptors() {
        tableView.sortDescriptors = tableView.sortDescriptors.compactMap {
            guard let key = $0.key,
                  let column = FontTableViewColumn(rawValue: key) else {
                return nil
            }
            return PDFFontSortDescriptor(key: column.key,
                                         ascending: $0.ascending,
                                         systemAvailableFonts: systemAvailableFonts)
        }
    }

    @objc
    private func handleDoubleClick() {
        let row = tableView.clickedRow
        guard row >= 0, row < fonts.count else { return }
        let font = fonts[row]
        onDoubleClick?(font)
    }

    private func updateSystemAvailableFonts() {
        systemAvailableFonts = Set(fonts.compactMap {
            if FontUtil.getSystemFont(named: $0.displayName, size: 10) != nil {
                return $0.id
            } else {
                return nil
            }
        })
    }

    private func sort() {
        let unrecognizedSortDescriptors = tableView.sortDescriptors.filter { !($0 is PDFFontSortDescriptor) }
        if !unrecognizedSortDescriptors.isEmpty {
            assertionFailure("Found unrecognized sort descriptors: \(unrecognizedSortDescriptors)")
        }
        let sortDescriptors = tableView.sortDescriptors.compactMap { $0 as? PDFFontSortDescriptor } + [
            PDFFontSortDescriptor(key: FontTableViewColumn.nameColumn.key, ascending: true)
        ]
        fonts.sort { a, b in
            for descriptor in sortDescriptors {
                switch descriptor.compare(a, to: b) {
                case .orderedAscending:
                    return true
                case .orderedDescending:
                    return false
                case .orderedSame:
                    continue
                }
            }
            return false
        }
    }
}


//
// MARK: Data Source
//
extension FontTableViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int { fonts.count }

    func tableView(_ tableView: NSTableView,
                   sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        sort()
        tableView.reloadData()
    }
}


//
// MARK: Delegate
//
extension FontTableViewController: NSTableViewDelegate {
    private func makeTableCellView<T: NSTableCellView>(ofType: T.Type,
                                                       withIdentifier identifier: NSUserInterfaceItemIdentifier) -> T {
        let tableCellView = (tableView.makeView(withIdentifier: identifier, owner: self) as? T) ?? T(frame: .zero)
        tableCellView.identifier = identifier
        return tableCellView
    }

    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {
        guard let tableColumn else { return nil }
        let font = fonts[row]

        switch FontTableViewColumn(identifier: tableColumn.identifier) {
        case .nameColumn:
            return makeTableCellView(ofType: TextFieldTableCellView.self, withIdentifier: tableColumn.identifier).then {
                $0.configure(text: font.displayName)
            }
        case .typeColumn:
            return makeTableCellView(ofType: TextFieldTableCellView.self, withIdentifier: tableColumn.identifier).then {
                $0.configure(text: FontUtil.typeString(for: font))
            }
        case .subsetColumn:
            return makeTableCellView(ofType: CheckTableCellView.self, withIdentifier: tableColumn.identifier).then {
                $0.configure(checked: font.isSubset)
            }
        case .embeddedColumn:
            return makeTableCellView(ofType: CheckTableCellView.self, withIdentifier: tableColumn.identifier).then {
                $0.configure(checked: font.isEmbedded)
            }
        case .installedColumn:
            return makeTableCellView(ofType: CheckTableCellView.self, withIdentifier: tableColumn.identifier).then {
                $0.configure(checked: systemAvailableFonts.contains(font.id))
            }
        case nil:
            return nil
        }
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        // If the preview popover is open, follow the selection.
        guard let popover = previewPopover, popover.isShown else { return }
        showPreviewPopover(for: tableView.selectedRow)
    }
}
