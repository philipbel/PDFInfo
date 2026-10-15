
import Testing
import Foundation
@testable import PDFKitExt

private final class FixtureLocator {}

fileprivate func data(_ name: String) throws -> Data {
    let bundle = Bundle(for: FixtureLocator.self)
    let url = try #require(bundle.url(forResource: name, withExtension: "pdf", subdirectory: "test-pdfs"),
                           "missing fixture \(name).pdf")
    return try Data(contentsOf: url)
}

private func parse(_ name: String) throws -> PDFDocument? {
    PDFDocument(data: try data(name))
}


@Suite("Font parsing")
struct FontParsingTests {
    @Test("Base-14 Helvetica: not embedded, not subset, Type1")
    func base14() throws {
        let doc = try #require(try parse("base14_helvetica_not_embedded"))
        let helv = try #require(doc.fonts.first { $0.displayName == "Helvetica" })
        #expect(doc.pageSize == .a4)
        #expect(helv is PDFType1Font)
        #expect(helv.subtype == .type1)
        #expect(helv.isEmbedded == false)
        #expect(helv.isSubset == false)
    }

    @Test("Embedded TrueType-outline CID: CIDFontType2, embedded, subset")
    func cidType2() throws {
        let doc = try #require(try parse("type0_cid_font_type2_embedded_subset"))
        let f = try #require(doc.fonts.first { $0.displayName.contains("Plex") })
        let type0Font = try #require(f as? PDFType0Font)
        #expect(type0Font.descendant.subtype == .cidFontType2)
        #expect(doc.pageSize == .a4)
        #expect(f.subtype == .type0)
        #expect(f.isEmbedded == true)
        #expect(f.isSubset == true)
    }

    @Test("Embedded CFF-outline CID: CIDFontType0, embedded, subset")
    func cidType0() throws {
        let doc = try #require(try parse("type0_cid_font_type0_embedded_subset"))
        let f = try #require(doc.fonts.first { $0.displayName.contains("Plex") })
        let type0Font = try #require(f as? PDFType0Font)
        #expect(type0Font.descendant.subtype == .cidFontType0)
        #expect(doc.pageSize == .a4)
        #expect(f.subtype == .type0)
        #expect(f.isEmbedded == true)
        #expect(f.isSubset == true)
    }

    @Test("Embedded simple TrueType: TrueType subtype, embedded, subset")
    func simpleTrueType() throws {
        let doc = try #require(try parse("simple_truetype"))
        #expect(doc.pageSize == .a4)
        let f = try #require(doc.fonts.first { $0.displayName.contains("CoalescoMono") })
        #expect(f is PDFTrueTypeFont)
        #expect(f.subtype == .trueType)
        #expect(f.isEmbedded == true)
        #expect(f.isSubset == true)
    }

    @Test("Mixed document reports all distinct fonts")
    func mixed() throws {
        let doc = try #require(try parse("multi_font_mixed"))
        let names = Set(doc.fonts.map(\.displayName))
        #expect(names.contains("Helvetica"))
        #expect(names.contains("IBM Plex Sans Regular"))
        #expect(doc.fonts.contains { $0.displayName.contains("Plex") && $0.isEmbedded })
    }
}


@Suite("Document metadata")
struct MetadataTests {
    @Test("Version and page count")
    func basics() throws {
        let doc = try #require(try parse("metadata_populated"))
        #expect(doc.pageCount == 1)
        #expect(doc.version.hasPrefix("1."))
    }

    @Test("Info dictionary fields")
    func info() throws {
        let doc = try #require(try parse("metadata_populated"))
        #expect(doc.metadata.title == "Fixture Title")
        #expect(doc.metadata.author == "Phil")
        #expect(doc.metadata.creator == "gen-test-pdf.py")
        #expect(doc.metadata.subject == "Font inspector fixture")
        #expect(doc.metadata.producer == "PyMuPDF")
    }

    @Test("Info dictionary omits keys absent from the source PDF")
    func infoOmitsUnsetKeys() throws {
        let doc = try #require(try parse("metadata_populated"))
        #expect(doc.metadata.keywords.isEmpty)
    }

    @Test("Page size parses to US Letter")
    func pageSize() throws {
        let doc = try #require(try parse("metadata_populated"))
        let size = try #require(doc.pageSize)
        #expect(size == .letter)   // uses your epsilon ==
    }

    @Test("Encrypted PDF opens and parses")
    func encrypted() throws {
        let doc = try #require(try parse("encrypted"))
        #expect(doc.pageCount == 1)
        #expect(doc.fonts.isEmpty)
    }
}


@Suite("Error handling")
struct ErrorTests {
    @Test("Malformed PDF throws")
    func malformed() throws {
        #expect(try parse("malformed_truncated") == nil)
    }
}
