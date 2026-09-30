import Cocoa
import Combine


class GeneralSettingsViewController: NSViewController {
    private let previewTextField = NSTextField(string: "").then {
        $0.placeholderString = String(localized: "Enter preview text here")
    }
    private let previewFontSizeTextField = NSTextField(string: "").then {
        $0.formatter = NumberFormatter().then {
            $0.allowsFloats = false
            $0.minimum = NSNumber(value: Settings.previewFontSizeRange.lowerBound)
            $0.maximum = NSNumber(value: Settings.previewFontSizeRange.upperBound)
        }
    }
    private let grid = NSGridView().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.rowAlignment = .firstBaseline
        $0.columnSpacing = 8
    }
    private let previewFontSizeStepper = NSStepper().then {
        $0.minValue = Double(Settings.previewFontSizeRange.lowerBound)
        $0.maxValue = Double(Settings.previewFontSizeRange.upperBound)
        $0.increment = 1
    }

    private var cancelBag = Set<AnyCancellable>()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView(frame: .zero)

        grid.do {
            $0.addRow(with: [
                NSTextField(labelWithString: String(localized: "Preview Text:")),
                previewTextField
            ])
            $0.addRow(with: [
                NSTextField(labelWithString: String(localized: "Font Size:")),
                NSStackView.horizontal(views: [
                    previewFontSizeTextField,
                    previewFontSizeStepper,
                ], alignment: .firstBaseline, spacing: 4)
            ])
            $0.column(at: 0).xPlacement = .trailing
        }
        view.addSubview(grid)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        previewTextField.target = self
        previewTextField.action = #selector(previewTextDidChange(_:))

        previewFontSizeTextField.target = self
        previewFontSizeTextField.action = #selector(textFontSizeDidChange(_:))

        previewFontSizeStepper.target = self
        previewFontSizeStepper.action = #selector(textFontSizeDidChange(_:))

        let textFieldFont = previewTextField.font ?? .systemFont(ofSize: NSFont.systemFontSize)
        let previewTextWidth = Settings.previewText.default.size(withAttributes: [.font: textFieldFont]).width + 50
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            grid.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            grid.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor),
            grid.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor),
            grid.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            previewTextField.widthAnchor.constraint(greaterThanOrEqualToConstant: previewTextWidth),
            previewFontSizeTextField.widthAnchor.constraint(equalToConstant: 50),
        ])

        UserDefaults.standard.publisher(for: \.previewText)
            .sink { [weak self] in
                self?.previewTextField.stringValue = $0
            }
            .store(in: &cancelBag)

        UserDefaults.standard.publisher(for: \.previewFontSize)
            .sink { [weak self] in
                self?.previewFontSizeStepper.integerValue = $0
                self?.previewFontSizeTextField.integerValue = $0
            }
            .store(in: &cancelBag)
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()

        // Save the current values. UserDefault's properties do validation
        UserDefaults.standard.previewText = previewTextField.stringValue
        UserDefaults.standard.previewFontSize = previewFontSizeTextField.integerValue
    }

    @objc
    private func textFontSizeDidChange(_ sender: NSControl) {
        UserDefaults.standard.previewFontSize = sender.integerValue
    }

    @objc
    private func previewTextDidChange(_ sender: NSControl) {
        UserDefaults.standard.previewText = sender.stringValue
    }
}

#Preview {
    GeneralSettingsViewController()
}
