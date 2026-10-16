import SwiftUI
import PDFEngine

struct DocumentAttributesView: View {
    @Environment(\.locale) private var locale

    let url: URL
    let document: PDFDocument
    let metadata: [(String, String?)]

    var body: some View {
        Section {
            LabeledContent("File:") {
                FileButton(url: url, type: .openFile)
            }
            .font(DocumentInspectorView.formFont)
        }

        Section {
            LabeledContent("PDF Version:") {
                Text(document.version.description)
            }
            .font(DocumentInspectorView.formFont)
            LabeledContent("Page Count:") {
                Text(String("\(document.pageCount)"))
            }
            .font(DocumentInspectorView.formFont)
            LabeledContent("Page Size:") {
                Group {
                    if let pageSize = document.pageSize {
                        Text(Self.formatPageSize(pageSize, locale: locale))
                    } else {
                        Text("N/A")
                    }
                }
                .accessibilityIdentifier("page_size")
            }
            .font(DocumentInspectorView.formFont)
        }

        Section {
            ForEach(metadata, id: \.0) { key, value in
                if let value {
                    LabeledContent(key, value: value)
                        .font(DocumentInspectorView.formFont)
                }
            }
        }
    }

    init(document: PDFDocument, url: URL) {
        self.url = url
        self.document = document
        metadata = if let metadata = document.metadata {
            [
                (String(localized: "Author:"), metadata.author),
                (String(localized: "Title:"), metadata.title),
                (String(localized: "Subject:"), metadata.subject),
                (String(localized: "Creator:"), metadata.creator),
                (String(localized: "Producer:"), metadata.producer),
                (String(localized: "Creation Date:"), metadata.creationDate?.formatted()),
                (String(localized: "Modification Date:"), metadata.modDate?.formatted()),
            ]
        } else {
            []
        }
    }

    private static func formatPageSize(_ pageSize: PDFPageSize, locale: Locale) -> String {
        let formatter = Self.makeFormatter(locale: locale)

        let (width, height) = if pageSize.orientation == .portrait {
            (pageSize.width, pageSize.height)
        } else {
            (pageSize.height, pageSize.width)
        }
        if pageSize.paperSize == .a4 {
            let paperSize = Self.doFormatPageSize(
                width: width,
                height: height,
                formatter: formatter,
                unit: UnitLength.millimeters
            )
            return String(
                localized: "A4 (\(paperSize), \(formatOrientation(pageSize.orientation)))",
                bundle: #bundle
            )
        } else if pageSize.paperSize == .letter {
            let paperSize = Self.doFormatPageSize(
                width: width,
                height: height,
                formatter: formatter,
                unit: UnitLength.inches
            )
            return String(
                localized: "Letter (\(paperSize), \(formatOrientation(pageSize.orientation)))",
                bundle: #bundle
            )
        } else {
            // Pick units based on the measurement system
            let unit: UnitLength = locale.measurementSystem == .us ? .inches : .centimeters
            return Self.doFormatPageSize(width: width, height: height, formatter: formatter, unit: unit)
        }
    }

    private static func makeFormatter(locale: Locale) -> MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.locale = locale
        formatter.unitStyle = .short
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }

    private static func doFormatPageSize(
        width: Measurement<UnitLength>,
        height: Measurement<UnitLength>,
        formatter: MeasurementFormatter,
        unit: UnitLength
    ) -> String {
        let w = formatter.string(from: width.converted(to: unit))
        let h = formatter.string(from: height.converted(to: unit))
        return "\(w) ⨉ \(h)"
    }

    private static func formatOrientation(_ orientation: PDFPageSizeOrientation) -> String {
        switch orientation {
        case .portrait: String(localized: "Portrait")
        case .landscape: String(localized: "Landscape")
        @unknown default:
            ""
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    let url = Bundle.main.url(forResource: "multi_font_mixed", withExtension: "pdf")!
    let data = try! Data(contentsOf: url)
    let document = PDFDocument(data: data)!

    DocumentAttributesView(document: document, url: url)
}
