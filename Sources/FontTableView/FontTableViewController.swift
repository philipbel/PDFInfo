import AppKit
import SwiftUI
import PDFKitExt


final class FontTableViewController: NSViewController {
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
        tableView.sortDescriptors = [NSSortDescriptor(key: FontTableViewColumn.nameColumn.key, ascending: true)]

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

        let popover = NSPopover()
        popover.behavior = .transient // dismiss on click-away / Escape
        popover.contentViewController = FontQuickLookViewController(font: font)
        popover.show(relativeTo: anchorRect, of: tableView, preferredEdge: .maxY)
        previewPopover = popover
    }

    private func configureColumns() {
        for column in FontTableViewColumn.allColumns {
            let tableColumn = NSTableColumn(identifier: column.identifier)
            tableColumn.title = column.title
            tableColumn.sortDescriptorPrototype = NSSortDescriptor(key: column.key, ascending: true)
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
        switch column.identifier.rawValue {
        case FontTableViewColumn.typeColumn.key: return fonts.map(FontUtil.typeString(for:))
        // the other columns are checkboxes
        default: return []
        }
    }

    private func headerWidth(for column: NSTableColumn) -> CGFloat {
        let attrs = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: NSFont.systemFontSize)]
        return (column.title as NSString).size(withAttributes: attrs).width
    }

    func update(fonts: [any PDFFont]) {
        previewPopover?.close()

        self.fonts = fonts
        updateSystemAvailableFonts()
        sort(
            by: tableView.sortDescriptors.first ?? NSSortDescriptor(
                key: FontTableViewColumn.nameColumn.key,
                ascending: true
            )
        )
        tableView.reloadData()
        // Column sizing
        if !tableView.autosaveTableColumns {
            // On first run, first resize the columns based on the data
            sizeColumnsToFit()
            // Now load the user's preferences, if any
            tableView.autosaveTableColumns = true
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

    private func sort(by sortDescriptor: NSSortDescriptor) {
        guard let key = sortDescriptor.key else {
            return
        }

        fonts.sort { a, b in
            let (a, b) = sortDescriptor.ascending ? (a, b) : (b, a)
            let result: Bool
            switch key {
            case FontTableViewColumn.nameColumn.key:
                result = a.displayName.localizedStandardCompare(b.displayName) == .orderedAscending
            case FontTableViewColumn.typeColumn.key:
                result = FontUtil.typeString(for: a)
                    .localizedStandardCompare(FontUtil.typeString(for: b)) == .orderedAscending
            case FontTableViewColumn.embeddedColumn.key:
                result = (a.isEmbedded ? 1 : 0) < (b.isEmbedded ? 1 : 0)
            case FontTableViewColumn.subsetColumn.key:
                result = (a.isSubset ? 1 : 0) < (b.isSubset ? 1 : 0)
            case FontTableViewColumn.installedColumn.key:
                result = (systemAvailableFonts.contains(a.id) ? 1 : 0) < (systemAvailableFonts.contains(b.id) ? 1 : 0)
            default: return false
            }
            return result
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
        guard let sortDescriptor = tableView.sortDescriptors.first else {
            return
        }
        sort(by: sortDescriptor)
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
        guard let column = tableColumn else { return nil }
        let font = fonts[row]

        switch column.identifier.rawValue {
        case FontTableViewColumn.nameColumn.key:
            return makeTableCellView(ofType: TextFieldTableCellView.self, withIdentifier: column.identifier).then {
                $0.configure(text: font.displayName)
            }
        case FontTableViewColumn.typeColumn.key:
            return makeTableCellView(ofType: TextFieldTableCellView.self, withIdentifier: column.identifier).then {
                $0.configure(text: FontUtil.typeString(for: font))
            }
        case FontTableViewColumn.subsetColumn.key:
            return makeTableCellView(ofType: CheckTableCellView.self, withIdentifier: column.identifier).then {
                $0.configure(checked: font.isSubset)
            }
        case FontTableViewColumn.embeddedColumn.key:
            return makeTableCellView(ofType: CheckTableCellView.self, withIdentifier: column.identifier).then {
                $0.configure(checked: font.isEmbedded)
            }
        case FontTableViewColumn.installedColumn.key:
            return makeTableCellView(ofType: CheckTableCellView.self, withIdentifier: column.identifier).then {
                $0.configure(checked: systemAvailableFonts.contains(font.id))
            }
        default:
            return nil
        }
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        // If the preview popover is open, follow the selection.
        guard let popover = previewPopover, popover.isShown else { return }
        showPreviewPopover(for: tableView.selectedRow)
    }
}
