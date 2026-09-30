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
}
