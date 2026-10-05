import Cocoa
import PDFKitExt
import SettingsKit


extension UserDefaults {
    static let fontPreviewDetailsExpanded = Setting(key: "fontPreviewDetailsExpanded", default: false)
}


class FontPreviewViewController: NSViewController {
    private static let fitContentLayoutPriority = NSLayoutConstraint.Priority(
        NSLayoutConstraint.Priority.windowSizeStayPut.rawValue + 1)


    private var pdfFont: any PDFFont? {
        didSet {
            update()
        }
    }
    private var cancelBag = Set<AnyCancellable>()

    private lazy var grid = NSGridView().then {
        $0.rowAlignment = .firstBaseline
        $0.columnSpacing = 8

        $0.addRow(with: [
            NSTextField(labelWithString: String(localized: "Name:")),
            fontNameLabel
        ])
        $0.addRow(with: [
            NSTextField(labelWithString: String(localized: "Subtype:")),
            fontSubtypeLabel
        ])
        $0.addRow(with: [
            NSTextField(labelWithString: String(localized: "Embedded:")),
            fontEmbeddedLabel
        ])
        $0.addRow(with: [
            NSTextField(labelWithString: String(localized: "Subset:")),
            fontSubsetLabel
        ])
        $0.addRow(with: [
            NSTextField(labelWithString: String(localized: "File:")),
            fontFileLabel
        ])
        $0.column(at: 0).xPlacement = .trailing
        $0.column(at: 1).xPlacement = .leading
        $0.rowAlignment = .firstBaseline
    }
    private lazy var gridContainer = NSStackView.horizontal(views: [
        grid,
        NSStackView.horizontalSpacer,
    ], distribution: .fill, spacing: 0).then {
        $0.edgeInsets.left = 20
    }
    private let previewSectionLabel = NSTextField(labelWithString: String(localized: "Preview")).then {
        $0.font = .preferredFont(forTextStyle: .headline)
    }
    private let previewLabel = NSTextField(labelWithString: "").then {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    private lazy var previewBox = NSBox().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.contentView?.addSubview(previewLabel)
        $0.titlePosition = .noTitle
        $0.boxType = .primary

        NSLayoutConstraint.activate([
            previewLabel.leadingAnchor.constraint(equalTo: $0.layoutMarginsGuide.leadingAnchor),
            previewLabel.topAnchor.constraint(equalTo: $0.layoutMarginsGuide.topAnchor),
            previewLabel.trailingAnchor.constraint(equalTo: $0.layoutMarginsGuide.trailingAnchor),
            previewLabel.bottomAnchor.constraint(equalTo: $0.layoutMarginsGuide.bottomAnchor),
        ])
    }
    private lazy var fontDetailsDisclosureButton = NSButton().then {
        $0.bezelStyle = .disclosure
        $0.title = ""
        $0.setButtonType(.onOff)
        $0.state = UserDefaults.standard[\.fontPreviewDetailsExpanded] ? .on : .off
        $0.setAccessibilityTitleUIElement(fontDetailsDisclosureLabel)
        $0.target = self
        $0.action = #selector(toggleDetails(_:))
    }
    private lazy var fontDetailsDisclosureLabel = NSTextField(labelWithString: String(localized: "Font Details")).then {
        $0.font = .preferredFont(forTextStyle: .headline)
    }
    private lazy var disclosureContainer = NSStackView.horizontal(views: [
        fontDetailsDisclosureButton,
        fontDetailsDisclosureLabel,
    ], alignment: .firstBaseline, spacing: 2).then {
        $0.setHuggingPriority(Self.fitContentLayoutPriority, for: .vertical)
    }
    private let fontNameLabel = NSTextField(labelWithString: "").then {
        $0.isSelectable = true
    }
    private let fontSubtypeLabel = NSTextField(labelWithString: "").then {
        $0.isSelectable = true
    }
    private let fontEmbeddedLabel = NSTextField(labelWithString: "").then {
        $0.isSelectable = true
    }
    private let fontSubsetLabel = NSTextField(labelWithString: "").then {
        $0.isSelectable = true
    }
    private let fontFileLabel = NSTextField(labelWithString: "").then {
        $0.isSelectable = true
    }

    init(font pdfFont: any PDFFont? = nil) {
        self.pdfFont = pdfFont

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        fontDetailsDisclosureLabel.addGestureRecognizer(
            NSClickGestureRecognizer(target: fontDetailsDisclosureButton, action: #selector(NSControl.performClick)))

        view = NSView(frame: .zero)

        let container = NSStackView.vertical(views: [
            NSStackView.horizontal(views: [
                previewSectionLabel,
            ]).then {
                $0.edgeInsets.left = 10
                $0.setHuggingPriority(.defaultHigh, for: .vertical)
            },
            previewBox,
            disclosureContainer,
            gridContainer,
        ], alignment: .width, spacing: 10).then {
            $0.setCustomSpacing(20, after: previewBox)
            $0.setHuggingPriority(Self.fitContentLayoutPriority, for: .vertical)
        }
        view.addSubview(container)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            container.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            container.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            grid.heightAnchor.constraint(equalToConstant: 0)
                // Prevent the grid from growing vertically
                .setting(\.priority, to: Self.fitContentLayoutPriority),
            previewBox.widthAnchor.constraint(equalTo: view.layoutMarginsGuide.widthAnchor),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        UserDefaults.standard
            .publisher(for: \.previewText)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updatePreviewFont()
            }
            .store(in: &cancelBag)

        UserDefaults.standard
            .publisher(for: \.previewFontSize)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.updatePreviewFont(size: CGFloat(value))
            }
            .store(in: &cancelBag)

        update()
        updateDetailsVisibility(expanded: fontDetailsDisclosureButton.state == .on)
    }

    @objc
    private func toggleDetails(_ sender: NSButton) {
        let expanded = sender.state == .on
        UserDefaults.standard[\.fontPreviewDetailsExpanded] = expanded
        updateDetailsVisibility(expanded: expanded)
    }

    func configure(font pdfFont: any PDFFont) {
        self.pdfFont = pdfFont
    }

    private func updateDetailsVisibility(expanded: Bool) {
        gridContainer.isHidden = !expanded
    }

    private func update() {
        updatePreviewFont()

        fontNameLabel.stringValue = pdfFont?.displayName ?? ""
        fontSubtypeLabel.stringValue = pdfFont?.subtype.displayName ?? ""
        fontEmbeddedLabel.stringValue = pdfFont?.isEmbedded == true ? String(localized: "Yes") : String(localized: "No")
        fontSubsetLabel.stringValue = pdfFont?.isSubset == true ? String(localized: "Yes") : String(localized: "No")
    }

    private func updatePreviewFont(size previewFontSize: CGFloat? = nil) {
        let previewFontSize = previewFontSize ?? CGFloat(UserDefaults.standard[\.previewFontSize])

        let nsFont = pdfFont.flatMap {
            FontUtil.buildPreviewFont(from: $0, size: previewFontSize).previewFont
        }

        var previewFontURL: URL?
        if let nsFont {
            previewLabel.font = nsFont
            previewLabel.stringValue = UserDefaults.standard[\.previewText]
            previewFontURL = CTFontCopyAttribute(nsFont, kCTFontURLAttribute) as? URL
        } else {
            previewLabel.font = .systemFont(ofSize: previewFontSize)
            previewLabel.stringValue = String(localized: "No preview available")
        }
        if let previewFontURL {
            fontFileLabel.stringValue = previewFontURL.lastPathComponent
        } else {
            fontFileLabel.stringValue = String(localized: "Not installed")
        }
    }
}


#Preview(traits: .sizeThatFitsLayout) {
    let url = Bundle.main.url(forResource: "multi_font_mixed", withExtension: "pdf")!
    let document = PDFDocument(url: url)!

    FontPreviewViewController(font: document.fonts.first!)
}
