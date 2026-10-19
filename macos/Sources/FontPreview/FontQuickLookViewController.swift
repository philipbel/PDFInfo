// Copyright (c) 2026 Philip B. (philipbel)
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import Cocoa
import PDFEngine
import SettingsKit


class FontQuickLookViewController: NSViewController {
    private let pdfFont: PDFFont
    private let previewView = NSTextField(labelWithString: "")

    init(font pdfFont: PDFFont) {
        self.pdfFont = pdfFont
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView()

        let previewFontSize = UserDefaults.standard[\.previewFontSize]
        let (_, nsFont) = FontUtil.buildPreviewFont(from: pdfFont, size: CGFloat(previewFontSize))
        previewView.font = nsFont
        if nsFont != nil {
            previewView.stringValue = UserDefaults.standard[\.previewText]
        } else {
            previewView.stringValue = String(localized: "No preview available")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(previewView)
        previewView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
        ])
    }
    
}

#Preview(traits: .sizeThatFitsLayout) {
    let url = Bundle.main.url(forResource: "multi_font_mixed", withExtension: "pdf")!
    let data = try! Data(contentsOf: url)
    let document = PDFDocument(data: data)!

    FontQuickLookViewController(font: document.fonts.first!)
}
