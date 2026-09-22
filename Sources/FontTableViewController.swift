import AppKit
import SwiftUI


fileprivate struct Column {
    let title: String
    let key: String

    var identifier: NSUserInterfaceItemIdentifier {
        NSUserInterfaceItemIdentifier(key)
    }

    static let nameColumn = Column(title: "Name", key: "name")
    static let subtypeColumn = Column(title: "Subtype", key: "subtype")
    static let subsetColumn = Column(title: "Subset", key: "subset")
    static let embeddedColumn = Column(title: "Embedded?", key: "embedded")

    static let allColumns: [Column] = [
        .nameColumn,
        .subtypeColumn,
        .subsetColumn,
        .embeddedColumn
    ]
}


final class CheckCellView: NSTableCellView {
    var checkbox: NSButton!
}


final class FontTableViewController: NSViewController {
    private static let cellInset: CGFloat = 2
    private static let nameColumnMinWidth: CGFloat = 50

    private var fonts: [PDFFont]
    private let tableView = FontTableView()
    private var previewPopover: NSPopover?


    var onDoubleClick: ((PDFFont) -> Void)?

    init(fonts: [PDFFont]) {
        self.fonts = fonts
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
        togglePreviewPopover()
    }

    private func showPreviewPopover(for row: Int) {
        guard row >= 0, row < fonts.count else {
            previewPopover?.close()
            previewPopover = nil
            return
        }
        let font = fonts[row]
        let nameColumnIndex = tableView.column(withIdentifier: Column.nameColumn.identifier)
        let anchorRect = tableView.frameOfCell(atColumn: nameColumnIndex, row: row)

        let popover = NSPopover()
        popover.behavior = .transient // dismiss on click-away / Escape
        let popoverHostingViewController = NSHostingController(
            rootView: FontPreviewView(viewModel: FontPreviewViewModel(font: font))
        )
        popoverHostingViewController.sizingOptions = [.preferredContentSize]
        popover.contentViewController = popoverHostingViewController
        popover.show(relativeTo: anchorRect, of: tableView, preferredEdge: .maxY)
        previewPopover = popover
    }

    private func togglePreviewPopover() {
        if let existingPopover = previewPopover, existingPopover.isShown {
            existingPopover.close()
            previewPopover = nil
        } else {
            let row = tableView.selectedRow
            showPreviewPopover(for: row)
        }
    }

    private func configureColumns() {
        for column in Column.allColumns {
            let tableColumn = NSTableColumn(identifier: column.identifier)
            tableColumn.title = column.title
            tableColumn.sortDescriptorPrototype = NSSortDescriptor(key: column.key, ascending: true)
            tableView.addTableColumn(tableColumn)
        }
    }

    private func sizeColumnsToFit() {
        let cellFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let attrs = [NSAttributedString.Key.font: cellFont]

        let padding = 2 * Self.cellInset
        for column in tableView.tableColumns {
            switch column.identifier {
            case Column.nameColumn.identifier:
                column.minWidth = Self.nameColumnMinWidth + padding
                column.maxWidth = .infinity
            case Column.subsetColumn.identifier,
                Column.embeddedColumn.identifier:
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
        case Column.subtypeColumn.key: return fonts.map(\.subtype)
        // subset/embedded are checkboxes
        default: return []
        }
    }

    private func headerWidth(for column: NSTableColumn) -> CGFloat {
        let attrs = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: NSFont.systemFontSize)]
        return (column.title as NSString).size(withAttributes: attrs).width
    }

    func update(fonts: [PDFFont]) {
        self.fonts = fonts
        doUpdate()
    }

    private func doUpdate() {
        tableView.sortDescriptors = [NSSortDescriptor(key: Column.nameColumn.key, ascending: true)]
        fonts.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        tableView.reloadData()
        sizeColumnsToFit()
    }

    @objc
    private func handleDoubleClick() {
        let row = tableView.clickedRow
        guard row >= 0, row < fonts.count else { return }
        let font = fonts[row]
        onDoubleClick?(font)
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
            case Column.nameColumn.key:
                result = a.name.localizedStandardCompare(b.name) == .orderedAscending
            case Column.subtypeColumn.key:
                result = a.subtype.localizedStandardCompare(b.subtype) == .orderedAscending
            case Column.embeddedColumn.key:
                result = (a.embedded ? 1 : 0) < (b.embedded ? 1 : 0)
            case Column.subsetColumn.key:
                result = (a.subset ? 1 : 0) < (b.subset ? 1 : 0)
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
        case Column.nameColumn.key:
            return textCell( in: tableView,
                             id: column.identifier,
                             text: font.name)
        case Column.subtypeColumn.key:
            return textCell(in: tableView,
                            id: column.identifier,
                            text: font.subtype)

        case Column.subsetColumn.key:
            return checkCell(in: tableView,
                             id: column.identifier,
                             on: font.subset)

        case Column.embeddedColumn.key:
            return checkCell(in: tableView,
                             id: column.identifier,
                             on: font.embedded)

        default:
            return nil
        }
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        // If the preview popover is open, follow the selection.
        guard let popover = previewPopover, popover.isShown else { return }
        showPreviewPopover(for: tableView.selectedRow)
    }

    private func textCell(in tableView: NSTableView,
                          id: NSUserInterfaceItemIdentifier,
                          text: String,
                          font: NSFont? = nil) -> NSTableCellView {
        let cell = tableView.makeView(withIdentifier: id, owner: self) as? NSTableCellView
            ?? makeTextCell(id: id)
        cell.textField?.stringValue = text
        cell.textField?.font = font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        return cell
    }

    private func makeTextCell(id: NSUserInterfaceItemIdentifier) -> NSTableCellView {
        let cell = NSTableCellView()
        cell.identifier = id
        let tf = NSTextField(labelWithString: "")
        tf.lineBreakMode = .byTruncatingTail
        tf.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        cell.textField = tf
        cell.addSubview(tf)
        tf.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tf.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: Self.cellInset),
            tf.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -Self.cellInset),
            tf.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])
        return cell
    }

    private func checkCell(in tableView: NSTableView, id: NSUserInterfaceItemIdentifier,
                           on: Bool) -> NSView {
        let cell = tableView.makeView(withIdentifier: id, owner: self) as? CheckCellView
            ?? makeCheckCell(id: id)
        cell.checkbox.state = on ? .on : .off
        return cell
    }

    private func makeCheckCell(id: NSUserInterfaceItemIdentifier) -> CheckCellView {
        let cell = CheckCellView()
        cell.identifier = id
        let check = NSButton(checkboxWithTitle: "", target: nil, action: nil)
        check.isEnabled = false
        cell.checkbox = check
        cell.addSubview(check)
        check.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            check.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
            check.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])
        return cell
    }
}
