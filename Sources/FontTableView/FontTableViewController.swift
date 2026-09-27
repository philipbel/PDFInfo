import AppKit
import SwiftUI
import PDFKitExt


final class FontTableViewController: NSViewController {
    private static let nameColumnMinWidth: CGFloat = 50

    private var fonts: [any PDFFont] = []
    private var systemAvailableFonts: [String: any PDFFont] = [:]
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
        tableView.autosaveTableColumns = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsColumnResizing = true
        tableView.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle
        tableView.target = self // Selector target
        tableView.doubleAction = #selector(handleDoubleClick)
        tableView.setAccessibilityIdentifier("fonts-table")

        self.view = scrollView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        doUpdate()
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
        guard systemAvailableFonts[font.id] != nil else {
            return
        }

        let nameColumnIndex = tableView.column(withIdentifier: FontTableViewColumn.nameColumn.identifier)
        let anchorRect = tableView.frameOfCell(atColumn: nameColumnIndex, row: row)

        let popover = NSPopover()
        popover.behavior = .transient // dismiss on click-away / Escape
        let fontPreviewViewController = NSHostingController(rootView: FontPreviewView(font: font, showDetails: false))
        fontPreviewViewController.sizingOptions = . preferredContentSize
        popover.contentViewController = fontPreviewViewController
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

        let padding = 2 * FontTableView.cellInset
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
                column.minWidth = column.width
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
        self.fonts = fonts
        doUpdate()
    }

    private func doUpdate() {
        tableView.sortDescriptors = [NSSortDescriptor(key: FontTableViewColumn.nameColumn.key, ascending: true)]
        fonts.sort { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
        updateSystemAvailableFonts()
        tableView.reloadData()
        DispatchQueue.main.async { [weak self] in
            self?.sizeColumnsToFit()
        }
    }

    @objc
    private func handleDoubleClick() {
        let row = tableView.clickedRow
        guard row >= 0, row < fonts.count else { return }
        let font = fonts[row]
        guard systemAvailableFonts[font.id] != nil else { return }
        onDoubleClick?(font)
    }

    private func updateSystemAvailableFonts() {
        systemAvailableFonts = Dictionary(uniqueKeysWithValues: fonts.compactMap {
            if FontUtil.getSystemFont(named: $0.displayName, size: 10) != nil {
                return ($0.id, $0)
            } else {
                return nil
            }
        })
    }
}


//
// MARK: Data Source
//
extension FontTableViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int { fonts.count }

    func tableView(_ tableView: NSTableView,
                   sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        guard let sort = tableView.sortDescriptors.first,
              let key = sort.key else { return }
        fonts.sort { a, b in
            let result: Bool
            switch key {
            case FontTableViewColumn.nameColumn.key:
                result = a.displayName.localizedStandardCompare(b.displayName) == .orderedAscending
            case FontTableViewColumn.typeColumn.key:
                result = FontUtil.typeString(for: a)
                    .localizedStandardCompare(FontUtil.typeString(for: b)) == .orderedAscending
            case FontTableViewColumn.embeddedColumn.key:
                if let a = a as? any PDFProgramFont,
                   let b = b as? any PDFProgramFont {
                    result = (a.isEmbedded ? 1 : 0) < (b.isEmbedded ? 1 : 0)
                } else {
                    result = false
                }
            case FontTableViewColumn.subsetColumn.key:
                result = (a.isSubset ? 1 : 0) < (b.isSubset ? 1 : 0)
            case FontTableViewColumn.installedColumn.key:
                result = (systemAvailableFonts[a.id] != nil ? 1 : 0) < (systemAvailableFonts[b.id] != nil ? 1 : 0)
            default: return false
            }
            return sort.ascending ? result : !result
        }
        tableView.reloadData()
    }
}


//
// MARK: Delegate
//
extension FontTableViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {
        guard let column = tableColumn else { return nil }
        let font = fonts[row]

        switch column.identifier.rawValue {
        case FontTableViewColumn.nameColumn.key:
            return tableView.makeView(withIdentifier: column.identifier, owner: self) as? NSTableCellView
                ?? FontNameTableCellView(
                    identifier: column.identifier,
                    text: font.displayName,
                    quickLook: systemAvailableFonts[font.id] != nil
                    ? { [weak self] in self?.onDoubleClick?(font)}
                    : nil)
        case FontTableViewColumn.typeColumn.key:
            return tableView.makeView(withIdentifier: column.identifier, owner: self) as? NSTableCellView
            ?? TextFieldTableCellView(identifier: column.identifier, text: FontUtil.typeString(for: font))
        case FontTableViewColumn.subsetColumn.key:
            return tableView.makeView(withIdentifier: column.identifier, owner: self) as? CheckTableCellView
            ?? CheckTableCellView(identifier: column.identifier, checked: font.isSubset)
        case FontTableViewColumn.embeddedColumn.key:
            return tableView.makeView(withIdentifier: column.identifier, owner: self) as? CheckTableCellView
            ?? CheckTableCellView(
                identifier: column.identifier,
                checked: font.isEmbedded
            )
        case FontTableViewColumn.installedColumn.key:
            return tableView.makeView(withIdentifier: column.identifier, owner: self) as? CheckTableCellView
            ?? CheckTableCellView(identifier: column.identifier, checked: systemAvailableFonts[font.id] != nil)
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
