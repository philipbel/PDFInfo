import Cocoa

final class FontPreviewViewController: NSViewController {
    private static let padding: CGFloat = 10
    private let textField = NSTextField(labelWithString: "")
    private var settingObservations: [NSKeyValueObservation] = []

    var font: PDFFont? {
        didSet {
            if let font,
                let pointSize = textField.font?.pointSize {
                self.textField.font = FontUtil.getSystemFont(named: font.name, size: pointSize)
            } else {
                self.textField.font = NSFont.systemFont(ofSize: Settings.previewFontSize.default)
            }
        }
    }

    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    convenience init(font: PDFFont? = nil) {
        self.init(nibName: nil, bundle: nil)
        self.font = font
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let containerView = NSView()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.isEditable = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.lineBreakMode = .byWordWrapping
        textField.maximumNumberOfLines = 0
        textField.alignment = .center
        textField.font = NSFont.systemFont(ofSize: Settings.previewFontSize.default)
        // Cap width so long text wraps rather than making the view huge
        textField.preferredMaxLayoutWidth = 400

        containerView.addSubview(textField)
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Self.padding),
            textField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Self.padding),
            textField.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Self.padding),
            textField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Self.padding),
        ])
        self.view = containerView
        observeSettings()
    }

    private func observeSettings() {
        settingObservations = [
            UserDefaults.standard.observe(\.previewFontSize, options: [.initial, .new]) { [weak self] _, value in
                guard let fontSize = value.newValue else { return }
                DispatchQueue.main.async {
                    self?.textField.font = self?.textField.font?.withSize(fontSize)
                }
            },
            UserDefaults.standard.observe(\.previewText, options: [.initial, .new]) { [weak self] _, value in
                guard let previewText = value.newValue else { return }
                DispatchQueue.main.async {
                    self?.textField.stringValue = previewText
                }
            }
        ]
    }
}



#Preview("Font not set") {
    FontPreviewViewController(nibName: nil, bundle: nil)
}

#Preview("Font not installed") {
    FontPreviewViewController(font: PDFFont(id: "unnknown-font",
                                            name: "Unknown-Font",
                                            subtype: "TrueType",
                                            embedded: true,
                                            subset: false))
}

#Preview("Helvetica") {
    FontPreviewViewController(font: PDFFont(id: "helvetica",
                                            name: "Helvetica",
                                            subtype: "TrueType",
                                            embedded: true,
                                            subset: false))
}

#Preview("Zapfino") {
    FontPreviewViewController(font: PDFFont(id: "zapfino",
                                            name: "Zapfino",
                                            subtype: "TrueType",
                                            embedded: true,
                                            subset: false))
}
