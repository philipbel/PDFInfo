// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

#include "font_program.hh"
#include <assert.h>


using namespace std;


optional<pdf_font_program> parseFontProgram(pdf_font_subtype subtype,
                                            QPDFObjectHandle fontDescriptorDictionary) {
    switch (subtype) {
    case PDF_FONT_SUBTYPE_TYPE0:
    case PDF_FONT_SUBTYPE_TYPE3:
        break;
    case PDF_FONT_SUBTYPE_TYPE1:
    case PDF_FONT_SUBTYPE_MM_TYPE1:
    case PDF_FONT_SUBTYPE_TRUETYPE:
    case PDF_FONT_SUBTYPE_CID_FONT_TYPE0:
    case PDF_FONT_SUBTYPE_CID_FONT_TYPE2:
        pdf_font_program_kind programKind;
        auto programStream = fontDescriptorDictionary.getKeyIfDict("/FontFile");
        if (programStream.isStream()) {
            programKind = PDF_FONT_PROGRAM_KIND_TYPE1;
        } else if ((programStream = fontDescriptorDictionary.getKeyIfDict("/FontFile2"))
                       .isStream()) {
            programKind = PDF_FONT_PROGRAM_KIND_TRUE_TYPE;
        } else if ((programStream = fontDescriptorDictionary.getKeyIfDict("/FontFile3"))
                       .isStream()) {
            string programSubtype;
            if (!programStream.getDict().getKeyIfDict("/Subtype").getValueAsName(programSubtype)) {
                break;
            }
            if (programSubtype == "/Type1C") {
                programKind = PDF_FONT_PROGRAM_KIND_TYPE1C;
            } else if (programSubtype == "/CIDFontType0C") {
                programKind = PDF_FONT_PROGRAM_KIND_CID_FONT_TYPE0C;
            } else if (programSubtype == "/OpenType") {
                programKind = PDF_FONT_PROGRAM_KIND_OPEN_TYPE;
            } else {
                break;
            }
        } else {
            break;
        }
        shared_ptr<Buffer> streamData;
        try {
            streamData = programStream.getStreamData();
        } catch (...) {
            break;
        }
        if (!streamData || !streamData->getBuffer() || streamData->size() == 0) {
            return nullopt;
        }
        return make_optional(pdf_font_program{
            .kind = programKind,
            .data = streamData,
        });
    }
    return nullopt;
}


enum pdf_font_program_kind pdf_font_program_get_kind(const struct pdf_font_program *p) {
    assert(p != nullptr);
    return p->kind;
}


size_t pdf_font_program_get_size(const struct pdf_font_program *p) {
    assert(p != nullptr);
    assert(p->data != nullptr);
    return p->data->size();
}


const uint8_t *pdf_font_program_get_data(const struct pdf_font_program *p) {
    assert(p != nullptr);
    assert(p->data != nullptr);
    return p->data->getBuffer();
}
