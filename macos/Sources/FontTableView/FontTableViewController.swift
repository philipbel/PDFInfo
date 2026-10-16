import AppKit
import PDFEngine
import OSLog


final class FontTableViewController: NSViewController {
    private static let logger = Logger(subsystem: "PDFInfo", category: className())

    private static let nameColumnMinWidth: CGFloat = 50

    private var fonts: [PDFFont] = []
    private var systemAvailableFonts: Set<PDFFont.ID> = Set()
    private let tableView = FontTableView()
    private var previewPopover: NSPopover?

    var onDoubleClick: ((PDFFont) -> Void)?

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
        // Initially, sort ascending by name
        tableView.sortDescriptors = [FontTableViewColumn.nameColumn.sortDescriptor(ascending: true)]
        // Now load the user's preferences, if any
        // This must happen after setting sortDescriptors, so the user's sorting order is applied
        // sizeColumnsToFit() will later resize the columns based on content
        tableView.autosaveTableColumns = true

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
            tableColumn.headerToolTip = column.toolTip
            // Default sort descriptor for this column
            tableColumn.sortDescriptorPrototype = column.sortDescriptor(ascending: true)
            tableView.addTableColumn(tableColumn)
        }
    }

    private func sizeColumnsToFit() {
        let cellFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let attrs = [NSAttributedString.Key.font: cellFont]

        for tableViewColumn in tableView.tableColumns {
            guard let column = FontTableViewColumn(identifier: tableViewColumn.identifier) else {
                assertionFailure("Unrecognized column with identifier \(tableViewColumn.identifier)")
                continue
            }

            switch column {
            case .nameColumn:
                tableViewColumn.minWidth = Self.nameColumnMinWidth + FontTableView.columnHorizontalPadding
                tableViewColumn.maxWidth = .infinity
                tableViewColumn.resizingMask = [ .autoresizingMask, .userResizingMask ]
            case .subsetColumn,
                    .embeddedColumn,
                    .installedColumn:
                tableViewColumn.width = headerWidth(for: tableViewColumn) + FontTableView.columnHorizontalPadding
                tableViewColumn.minWidth = tableViewColumn.width
                tableViewColumn.maxWidth = tableViewColumn.width
                tableViewColumn.resizingMask = [] // no resizing
            case .typeColumn:
                let maxContentWidth = columnValues(for: tableViewColumn)
                    .reduce(headerWidth(for: tableViewColumn)) { partialResult, value in
                        max(partialResult, (value as NSString).size(withAttributes: attrs).width)
                    }
                tableViewColumn.width = maxContentWidth + FontTableView.columnHorizontalPadding
                tableViewColumn.minWidth = tableViewColumn.width
                tableViewColumn.maxWidth = tableViewColumn.width
                tableViewColumn.resizingMask = [] // no resizing
            }
        }
    }

    private func columnValues(for column: NSTableColumn) -> [String] {
        if let c = FontTableViewColumn(identifier: column.identifier),
           c == .typeColumn {
            return fonts.map { $0.displayType.localizedString }
        } else {
            // the other columns are checkboxes
            return []
        }
    }

    private func headerWidth(for column: NSTableColumn) -> CGFloat {
        let attrs = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: NSFont.systemFontSize)]
        return (column.title as NSString).size(withAttributes: attrs).width
    }

    func update(fonts: [PDFFont]) {
        previewPopover?.close()

        // New fonts
        self.fonts = fonts
        updateSystemAvailableFonts()
        // Now sort
        sort()
        // Only then reload
        tableView.reloadData()
        // Column sizing after the data has been reloaded
        sizeColumnsToFit()
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
            if FontUtil.getSystemFont(for: $0, size: 10) != nil {
                return $0.id
            } else {
                return nil
            }
        })
    }

    private func sort() {
        var sortDescriptors = tableView.sortDescriptors
        // Append the name sort descriptor at the end as a tie-breaker if not already in there
        if !tableView.sortDescriptors.contains(where: {
            $0.key == FontTableViewColumn.nameColumn.key
        }) {
            sortDescriptors.append(FontTableViewColumn.nameColumn.sortDescriptor(ascending: true))
        }
        let orderAndColumnPairs = sortDescriptors.compactMap {
            (descriptor: NSSortDescriptor) -> (ascending: Bool, column: FontTableViewColumn)? in
            guard let key = descriptor.key else {
                assertionFailure("No key")
                return nil
            }
            guard let column = FontTableViewColumn(rawValue: key) else {
                assertionFailure("No column for key '\(key)'")
                return nil
            }
            return (ascending: descriptor.ascending, column: column)
        }
        Self.logger.debug("Sorting \(self.fonts.count) font(s) by \(orderAndColumnPairs)")

        fonts.sort { a, b in
            for (ascending, column) in orderAndColumnPairs {
                let result: ComparisonResult
                switch column {
                case .nameColumn:
                    result = (a.displayName ?? "").localizedStandardCompare(b.displayName ?? "")
                case .typeColumn:
                    result = a.displayType.localizedString.localizedStandardCompare(b.displayType.localizedString)
                case .embeddedColumn:
                    result = Self.compare(a.isEmbedded, b.isEmbedded)
                case .subsetColumn:
                    result = Self.compare(a.isSubset, b.isSubset)
                case .installedColumn:
                    result = Self.compare(systemAvailableFonts.contains(a.id), systemAvailableFonts.contains(b.id))
                }

                if result == .orderedSame {
                    // Try next descriptor
                    continue
                }

                if ascending {
                    return result == .orderedAscending
                } else {
                    return result == .orderedDescending
                }
            }
            return false
        }
    }

    private static func compare(_ a: Bool, _ b: Bool) -> ComparisonResult {
        return switch (a ? 1 : 0) - (b ? 1 : 0) {
        case -1:
                .orderedAscending
        case 1:
                .orderedDescending
        default:
                .orderedSame
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
                $0.configure(text: font.displayName ?? "")
            }
        case .typeColumn:
            return makeTableCellView(ofType: TextFieldTableCellView.self, withIdentifier: tableColumn.identifier).then {
                $0.configure(text: font.displayType.localizedString)
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


#Preview(traits: .sizeThatFitsLayout) {
    let url = Bundle.main.url(forResource: "multi_font_mixed", withExtension: "pdf")!
    let data = try! Data(contentsOf: url)
    let document = PDFDocument(data: data)!

    let viewController = FontTableViewController()
    viewController.loadViewIfNeeded()
    viewController.update(fonts: document.fonts)
    return viewController
}
