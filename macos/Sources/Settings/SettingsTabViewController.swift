import Cocoa


final class SettingsTabViewController: NSTabViewController {
    override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, willSelect: tabViewItem)
        guard let window = view.window,
              let size = tabViewItem?.viewController?.preferredContentSize else { return }

        var frame = window.frame
        let newSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: size)).size
        frame.origin.y += frame.height - newSize.height // keep top-left fixed
        frame.size = newSize

        guard frame != window.frame else {
            return
        }

        // Hide the tabView during the transition
        // See https://gist.github.com/florianpircher/be8507c20a888614296ba8123335fc4b
        tabView.isHidden = true
        NSAnimationContext.runAnimationGroup { context in
            context.timingFunction = .init(name: .default)
            context.duration = 0.3
            window.animator().setFrame(frame, display: true)
        } completionHandler: {
            DispatchQueue.main.async {
                tabView.isHidden = false
            }
        }
    }

    override func addTabViewItem(_ tabViewItem: NSTabViewItem) {
        super.addTabViewItem(tabViewItem)

        // Get the widest view
        let maxWidth = tabViewItems.compactMap {
            $0.viewController
        }.reduce(into: 0) { partialResult, viewController in
            viewController.view.layoutSubtreeIfNeeded()
            viewController.view.setFrameSize(viewController.view.fittingSize)
            viewController.preferredContentSize = viewController.view.fittingSize
            partialResult = max(partialResult, viewController.preferredContentSize.width)
        }
        // Resize each view controller to the widest width
        tabViewItems
            .compactMap(\.viewController)
            .forEach {
                $0.preferredContentSize.width = maxWidth
                $0.view.setFrameSize($0.preferredContentSize)
            }
    }
}
