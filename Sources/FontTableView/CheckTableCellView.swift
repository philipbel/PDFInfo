import Cocoa


final class CheckTableCellView: NSTableCellView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        let imageView = NSImageView()
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        self.imageView = imageView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(checked: Bool) {
        if checked {
            imageView?.image = NSImage(systemSymbolName: "checkmark",
                                       accessibilityDescription: String(localized: "Yes", comment: "Checkmark"))
            self.setAccessibilityTitle(String(localized: "Yes", comment: "Checkmark"))
        } else {
            imageView?.image = nil
            self.setAccessibilityTitle(String(localized: "No", comment: "Checkmark"))
        }
    }
}
