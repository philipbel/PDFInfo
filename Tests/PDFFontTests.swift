import Testing
@testable import PDF_Info

@Suite("PDFFont tests")
struct PDFFontTests {
    @Test func testInitializer() throws {
        let font1 = PDFFont(id: "font1", name: "font1", subtype: "subtype1", embedded: true, subset: false)
        #expect(font1.name == "font1")
        #expect(font1.subtype == "subtype1")
        #expect(font1.embedded == true)
        #expect(font1.subset == false)

        let font2 = PDFFont(id: "font2", name: "font2", subtype: "subtype2", embedded: false, subset: true)
        #expect(font2.name == "font2")
        #expect(font2.subtype == "subtype2")
        #expect(font2.embedded == false)
        #expect(font2.subset == true)
    }
}
