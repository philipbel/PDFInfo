import Cocoa


final class FontNameTableCellView: NSTableCellView {
    private var quickLook: (() -> Void)?
    private var quickLookButton: NSButton!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    convenience init(identifier: NSUserInterfaceItemIdentifier, text: String, quickLook: (() -> Void)?) {
        self.init(frame: .zero)
        configure(identifier: identifier, text: text, quickLook: quickLook)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(identifier: NSUserInterfaceItemIdentifier, text: String, quickLook: (() -> Void)?) {
        self.identifier = identifier
        self.textField?.stringValue = text
        self.quickLook = quickLook
        quickLookButton.isHidden = (quickLook == nil)
    }

    private func setup() {
        let textField = NSTextField(labelWithString: "")
        textField.lineBreakMode = .byTruncatingTail
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.translatesAutoresizingMaskIntoConstraints = false
        self.textField = textField
        addSubview(textField)

        quickLookButton = NSButton()
        quickLookButton.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Preview font")
        quickLookButton.isBordered = false
        quickLookButton.setAccessibilityLabel("Preview font")
        quickLookButton.target = self
        quickLookButton.action = #selector(onQuickLook(sender:))
        quickLookButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(quickLookButton)

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: FontTableView.cellInset),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor),
            quickLookButton.leadingAnchor
                .constraint(greaterThanOrEqualTo: textField.trailingAnchor, constant: FontTableView.cellInset * 2),
            quickLookButton.trailingAnchor
                .constraint(equalTo: trailingAnchor, constant: -FontTableView.cellInset),
            quickLookButton.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @objc
    private func onQuickLook(sender: Any?) {
        quickLook?()
    }
}
