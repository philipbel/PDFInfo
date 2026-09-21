
import Testing
import Foundation
@testable import PDF_Info

private final class FixtureLocator {}

private func data(_ name: String) throws -> Data {
    let bundle = Bundle(for: FixtureLocator.self)
    let url = try #require(bundle.url(forResource: name, withExtension: "pdf", subdirectory: "test-pdfs"),
                           "missing fixture \(name).pdf")
    return try Data(contentsOf: url)
}

private func parse(_ name: String) throws -> PDFDocumentModel {
    try PDFDocumentModel(data: try data(name))
}


@Suite("Font parsing")
struct FontParsingTests {
    @Test("Base-14 Helvetica: not embedded, not subset, Type1")
    func base14() throws {
        let doc = try parse("base14_helvetica_not_embedded")
        let helv = try #require(doc.fonts.first { $0.name == "Helvetica" })
        #expect(helv.subtype == "Type1")
        #expect(helv.embedded == false)
        #expect(helv.subset == false)
    }

    @Test("Embedded TrueType-outline CID: CIDFontType2, embedded, subset")
    func cidType2() throws {
        let doc = try parse("type0_cid_font_type2_embedded_subset")
        let f = try #require(doc.fonts.first { $0.name.contains("Plex") })
        #expect(f.subtype == "CIDFontType2")
        #expect(f.embedded == true)
        #expect(f.subset == true)
    }

    @Test("Embedded CFF-outline CID: CIDFontType0, embedded, subset")
    func cidType0() throws {
        let doc = try parse("type0_cid_font_type0_embedded_subset")
        let f = try #require(doc.fonts.first { $0.name.contains("Plex") })
        #expect(f.subtype == "CIDFontType0")
        #expect(f.embedded == true)
        #expect(f.subset == true)
    }

    @Test("Embedded simple TrueType: TrueType subtype, embedded, subset")
    func simpleTrueType() throws {
        let doc = try parse("simple_truetype")
        let f = try #require(doc.fonts.first { $0.name.contains("CoalescoMono") })
        #expect(f.subtype == "TrueType")
        #expect(f.embedded == true)
        #expect(f.subset == true)
    }

    @Test("Mixed document reports all distinct fonts")
    func mixed() throws {
        let doc = try parse("multi_font_mixed")
        let names = Set(doc.fonts.map(\.name))
        #expect(names.contains("Helvetica"))
        #expect(names.contains("Times-Roman"))
        #expect(doc.fonts.contains { $0.name.contains("Plex") && $0.embedded })
    }
}


@Suite("Document metadata")
struct MetadataTests {
    @Test("Version and page count")
    func basics() throws {
        let doc = try parse("metadata_populated")
        #expect(doc.pageCount == 1)
        #expect(doc.version.hasPrefix("1."))
    }

    @Test("Info dictionary fields")
    func info() throws {
        let doc = try parse("metadata_populated")
        #expect(doc.metadata["Title"] == "Fixture Title")
        #expect(doc.metadata["Author"] == "Phil")
        #expect(doc.metadata["Creator"] == "gen-test-pdf.py")
        #expect(doc.metadata["Subject"] == "Font inspector fixture")
        #expect(doc.metadata["Producer"] == "PyMuPDF")
    }

    @Test("Info dictionary omits keys absent from the source PDF")
    func infoOmitsUnsetKeys() throws {
        let doc = try parse("metadata_populated")
        #expect(doc.metadata["Keywords"] == nil)
    }

    @Test("Page size parses to US Letter")
    func pageSize() throws {
        let doc = try parse("metadata_populated")
        let size = try #require(doc.pageSize)
        #expect(size == .letter)   // uses your epsilon ==
    }

    @Test("Encrypted PDF opens and parses")
    func encrypted() throws {
        let doc = try parse("encrypted")
        #expect(doc.pageCount == 1)
        #expect(doc.fonts.isEmpty)
    }
}


@Suite("PDFDocumentModel tests")
struct PDFDocumentTests {
    @Test("PDFDocumentModel initializer")
    func initializer() {
        let fonts = [PDFFont(id: "font", name: "font", subtype: "subtype", embedded: true, subset: false)]
        let version = "3.14"
        let pageCount = 42
        let pageSize = PDFPageSize(width: Measurement(value: 2, unit: .centimeters), height: Measurement(value: 3, unit: .feet))
        let metadata = [
            "key": "value"
        ]
        let doc = PDFDocumentModel(
            fonts: fonts,
            version: version,
            pageCount: pageCount,
            pageSize: pageSize,
            metadata: metadata,
        )
        #expect(doc.fonts == fonts)
        #expect(doc.version == version)
        #expect(doc.pageCount == pageCount)
        #expect(doc.pageSize == pageSize)
        #expect(doc.metadata == metadata)
    }
}



@Suite("Error handling")
struct ErrorTests {
    @Test("Malformed PDF throws")
    func malformed() throws {
        #expect(throws: (any Error).self) {
            _ = try parse("malformed_truncated")
        }
    }
}
