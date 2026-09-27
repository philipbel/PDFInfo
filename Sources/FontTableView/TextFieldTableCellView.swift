import Cocoa


final class TextFieldTableCellView: NSTableCellView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    convenience init(identifier: NSUserInterfaceItemIdentifier, text: String) {
        self.init(frame: .zero)
        configure(identifier: identifier, text: text)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(identifier: NSUserInterfaceItemIdentifier, text: String) {
        self.identifier = identifier
        textField?.stringValue = text
    }

    private func setup() {
        let textField = NSTextField(labelWithString: "")
        textField.lineBreakMode = .byTruncatingTail
        textField.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        self.textField = textField
        addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: FontTableView.cellInset),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -FontTableView.cellInset),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
