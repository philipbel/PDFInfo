import Cocoa


extension NSStackView {
    static func horizontal(
        views: [NSView],
        alignment: NSLayoutConstraint.Attribute? = nil,
        distribution: NSStackView.Distribution? = nil,
        spacing: CGFloat? = nil
    ) -> NSStackView {
        let stackView = NSStackView(views: views)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.orientation = .horizontal
        if let alignment {
            stackView.alignment = alignment
        }
        if let distribution {
            stackView.distribution = distribution
        }
        if let spacing {
            stackView.spacing = spacing
        }
        return stackView
    }

    static func vertical(
        views: [NSView],
        alignment: NSLayoutConstraint.Attribute? = nil,
        distribution: NSStackView.Distribution? = nil,
        spacing: CGFloat? = nil
    ) -> NSStackView {
        let stackView = NSStackView(views: views)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.orientation = .vertical
        if let alignment {
            stackView.alignment = alignment
        }
        if let distribution {
            stackView.distribution = distribution
        }
        if let spacing {
            stackView.spacing = spacing
        }
        return stackView
    }

    static var horizontalSpacer: NSView {
        NSView().then {
            $0.setContentHuggingPriority(.init(rawValue: 1), for: .horizontal)
            $0.heightAnchor.constraint(equalToConstant: 0).then {
                $0.priority = .defaultHigh
                $0.isActive = true
            }
        }
    }

    static var verticalSpacer: NSView {
        NSView().then {
            $0.setContentHuggingPriority(.init(rawValue: 1), for: .vertical)
            $0.widthAnchor.constraint(equalToConstant: 0).then {
                $0.priority = .defaultHigh
                $0.isActive = true
            }
        }
    }
}
