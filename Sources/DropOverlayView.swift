import Cocoa
import SwiftUI


fileprivate struct DropOverlayInfoView: View {
    let count: Int

    private var message: String {
        count == 1 ? "Drop 1 PDF file to open"
                   : "Drop \(count) PDF files to open"
    }

    var body: some View {
        ZStack {
            Color.accentColor.opacity(0.1)
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 12,
                bottomTrailingRadius: 12,
                topTrailingRadius: 0,
                style: .continuous
            )
            .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 3, dash: [10]))
            .padding(1.5)

            VStack(spacing: 8) {
                Image(systemName: "doc.badge.plus")
                    .symbolRenderingMode(.multicolor)
                    .foregroundStyle(.secondary, .green)
                    .font(.system(size: 48))
                Text(message)
                    .font(.title2)
            }
            .foregroundStyle(.secondary)
        }
        .allowsHitTesting(false)
    }
}


final class DropOverlayView: NSView {
    weak var destination: (NSDraggingDestination)?
    var fileCount: ((NSDraggingInfo) -> Int)?

    private lazy var overlay: NSHostingView<DropOverlayInfoView> = {
        let v = NSHostingView(rootView: DropOverlayInfoView(count: 0))
        v.translatesAutoresizingMaskIntoConstraints = false
        v.alphaValue = 0
        v.isHidden = false
        addSubview(v)
        NSLayoutConstraint.activate([
            v.leadingAnchor.constraint(equalTo: leadingAnchor),
            v.trailingAnchor.constraint(equalTo: trailingAnchor),
            v.topAnchor.constraint(equalTo: topAnchor),
            v.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        return v
    }()

    init(frame: NSRect,
         draggedTypes: [NSPasteboard.PasteboardType],
         destination: NSDraggingDestination? = nil,
         fileCount: ((NSDraggingInfo) -> Int)?) {
        super.init(frame: frame)

        self.destination = destination
        self.fileCount = fileCount
        registerForDraggedTypes(draggedTypes)
        _ = overlay // instantiate the overlay view so it's mounted
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let op = destination?.draggingEntered?(sender) ?? []
        let count = fileCount?(sender) ?? 0
        if op == .copy, count > 0 {
            overlay.rootView = DropOverlayInfoView(count: count)
            toggleOverlay(visible: true)
        } else {
            toggleOverlay(visible: false)
        }
        return op
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        toggleOverlay(visible: false)
        return destination?.performDragOperation?(sender) ?? false

    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        toggleOverlay(visible: false)
        destination?.draggingExited?(sender)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil // transparent to mouse events;,still receives drags
    }

    private func toggleOverlay(visible: Bool, animated: Bool = true) {
        if animated {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.3
                overlay.animator().alphaValue = visible ? 1 : 0
            }
        } else {
            overlay.alphaValue = visible ? 1 : 0
        }
    }
}


#Preview {
    DropOverlayInfoView(count: 1)
        .frame(width: 200, height: 200)
}

#Preview {
    DropOverlayInfoView(count: 2)
        .frame(width: 200, height: 200)
}
