import Observation


@Observable
final class FontPreviewViewModel {
    var font: PDFFont?

    init(font: PDFFont? = nil) {
        self.font = font
    }
}
