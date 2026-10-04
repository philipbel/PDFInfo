import Cocoa
import Sparkle
import Combine


class UpdateSettingsViewController: NSViewController {
    /// Update interval in seconds
    private enum UpdateInterval: Int, CaseIterable {
        case hourly = 3_600
        case daily = 86_400
        case weekly = 604_800
        case monthly = 2_592_000

        var displayName: String {
            switch self {
            case .hourly:
                String(localized: "Hourly")
            case .daily:
                String(localized: "Daily")
            case .weekly:
                String(localized: "Weekly")
            case .monthly:
                String(localized: "Monthly")
            }
        }
    }
    private static let defaultUpdateInterval = UpdateInterval.weekly

    let updater: SPUUpdater
    private var cancelBag = Set<AnyCancellable>()
    private let checkCheckBox = NSButton(checkboxWithTitle: String(localized: "Check for updates:"),
                                         target: nil,
                                         action: nil)
    private let downloadUpdatesCheckBox = NSButton(checkboxWithTitle: String(localized: "Download automatically"),
                                                   target: nil,
                                                   action: nil)
    private let updateIntervalPopupButton = NSPopUpButton().then {
        $0.menu?.items = UpdateInterval.allCases.map { interval in
            NSMenuItem(title: interval.displayName, action: nil, keyEquivalent: "").then {
                $0.tag = interval.rawValue
            }
        }
    }
    private let checkForUpdatesButton = NSButton().then {
        $0.title = String(localized: "Check for Updates Now")
    }
    private let lastUpdateCheckLabel = NSTextField(labelWithString: "").then {
        $0.font = .preferredFont(forTextStyle: .footnote)
        $0.textColor = .secondaryLabelColor
    }

    init(updater: SPUUpdater) {
        self.updater = updater
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView(frame: .zero)

        let container = NSStackView.vertical(views: [
            NSStackView.vertical(views: [
                NSStackView.horizontal(views: [
                    checkCheckBox,
                    updateIntervalPopupButton
                ], alignment: .firstBaseline),
                NSStackView.horizontal(views: [
                    downloadUpdatesCheckBox,
                ]).then {
                    $0.edgeInsets.left = 20
                },
            ], alignment: .leading),
            NSStackView.vertical(views: [
                checkForUpdatesButton,
                lastUpdateCheckLabel,
            ]).then {
                $0.edgeInsets.top = 30
            }
        ])

        view.addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            container.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            container.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor),
            container.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor),
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        checkCheckBox.target = self
        checkCheckBox.action = #selector(checkForUpdatesCheckBoxClicked(_:))

        updateIntervalPopupButton.target = self
        updateIntervalPopupButton.action = #selector(updateIntervalDidChange(_:))

        downloadUpdatesCheckBox.target = self
        downloadUpdatesCheckBox.action = #selector(downloadAutomaticallyCheckBoxClicked(_:))

        checkForUpdatesButton.target = self
        checkForUpdatesButton.action = #selector(checkForUpdatesNow(_:))

        updater.publisher(for: \.automaticallyChecksForUpdates)
            .sink { [weak self] in
                self?.checkCheckBox.state = $0 ? .on : .off
                self?.updateIntervalPopupButton.isEnabled = $0
                self?.downloadUpdatesCheckBox.isEnabled = $0
            }
            .store(in: &cancelBag)

        updater.publisher(for: \.automaticallyDownloadsUpdates)
            .sink { [weak self] in
                self?.downloadUpdatesCheckBox.state = $0 ? .on : .off
            }
            .store(in: &cancelBag)

        updater.publisher(for: \.updateCheckInterval)
            .sink { [weak self] tag in
                let updateInterval = UpdateInterval(rawValue: Int(tag)) ?? Self.defaultUpdateInterval
                self?.updateIntervalPopupButton.selectItem(withTag: updateInterval.rawValue)
            }
            .store(in: &cancelBag)

        updater.publisher(for: \.lastUpdateCheckDate)
            .sink { [weak self] date in
                if let date {
                    self?.lastUpdateCheckLabel.stringValue = String(localized: "Last check: \(date.formatted())")
                } else {
                    self?.lastUpdateCheckLabel.stringValue = String(localized: "Never", comment: "Last update date")
                }
            }
            .store(in: &cancelBag)
    }

    @objc
    private func checkForUpdatesCheckBoxClicked(_ sender: NSControl) {
        updater.automaticallyChecksForUpdates = (checkCheckBox.state == .on)
    }

    @objc
    private func updateIntervalDidChange(_ sender: NSControl) {
        guard let tag = updateIntervalPopupButton.selectedItem?.tag else {
            return
        }
        let updateInterval = UpdateInterval(rawValue: tag) ?? Self.defaultUpdateInterval
        updater.updateCheckInterval = Double(updateInterval.rawValue)
    }

    @objc
    private func downloadAutomaticallyCheckBoxClicked(_ sender: NSControl) {
        updater.automaticallyDownloadsUpdates = (downloadUpdatesCheckBox.state == .on)
    }

    @objc
    private func checkForUpdatesNow(_ sender: Any?) {
        updater.checkForUpdates()
    }
}

#Preview {
    UpdateSettingsViewController(
        updater: SPUStandardUpdaterController(updaterDelegate: nil, userDriverDelegate: nil).updater
    )
}
