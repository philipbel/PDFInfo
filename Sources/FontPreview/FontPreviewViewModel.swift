import PDFKitExt
import SwiftUI
import SettingsKit


@Observable
final class FontPreviewViewModel {
    let pdfFont: any PDFFont
    private(set) var isSystemFont: Bool = false
    private(set) var previewFont: Font? = nil
    private(set) var previewFontURL: URL? = nil
    let subtypeString: String
    private let program: PDFFontProgram?
    var programKindString: String? {
        program?.kind.displayName
    }
    let flagString: String
    private(set) var previewText = UserDefaults.previewText.default
    private(set) var previewFontSize = UserDefaults.previewFontSize.default
    @ObservationIgnored
    private var cancelBag = Set<AnyCancellable>()

    init(font pdfFont: any PDFFont) {
        self.pdfFont = pdfFont
        subtypeString = pdfFont.subtype.displayName

        let descriptor = (pdfFont as? PDFType0Font)?.descendant.descriptor
        ?? (pdfFont as? any PDFProgramFont)?.descriptor

        program = descriptor?.program

        if let flagsDict = descriptor?.flags.displayDictionary {
            flagString = flagsDict.compactMap { key, value in
                value ? key : nil
            }
            .sorted()
            .joined(separator: ", ")
        } else {
            flagString = ""
        }

        UserDefaults.standard
            .publisher(for: \.previewText)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.previewText = value
            }
            .store(in: &cancelBag)

        UserDefaults.standard
            .publisher(for: \.previewFontSize)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.previewFontSize = value
                self?.updatePreviewFont()
            }
            .store(in: &cancelBag)

        updatePreviewFont()
    }

    private func updatePreviewFont() {
        let (isSystemFont, nsFont) = buildPreviewFont()
        self.isSystemFont = isSystemFont

        previewFont = if let nsFont {
            Font(nsFont)
        } else {
            nil
        }

        previewFontURL = nsFont.flatMap {
            CTFontCopyAttribute($0, kCTFontURLAttribute) as? URL
        }
    }

    private func buildPreviewFont() -> (isSystemFont: Bool, previewFont: NSFont?) {
        if let systemFont = FontUtil.getSystemFont(named: pdfFont.displayName, size: CGFloat(previewFontSize)) {
            return (isSystemFont: true, previewFont: systemFont)
        }
        guard let program else {
            return (isSystemFont: false, previewFont: nil)
        }

        guard let provider = CGDataProvider(data: program.data as CFData) else {
            return (isSystemFont: false, previewFont: nil)
        }
        guard let cgFont = CGFont(provider) else {
            return (isSystemFont: false, previewFont: nil)
        }
        let ctFont = CTFontCreateWithGraphicsFont(cgFont, CGFloat(previewFontSize), nil, nil)
        return (isSystemFont: false, ctFont as NSFont)
    }
}
