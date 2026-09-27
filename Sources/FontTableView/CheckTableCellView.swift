import Cocoa


final class CheckTableCellView: NSTableCellView {
    var checkbox: NSButton!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    convenience init(identifier: NSUserInterfaceItemIdentifier, checked: Bool) {
        self.init(frame: .zero)
        configure(identifier: identifier, checked: checked)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(identifier: NSUserInterfaceItemIdentifier, checked: Bool) {
        self.identifier = identifier
        checkbox.state = checked ? .on : .off
    }

    private func setup() {
        checkbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
        checkbox.isEnabled = false

        addSubview(checkbox)
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            checkbox.centerXAnchor.constraint(equalTo: centerXAnchor),
            checkbox.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

}
