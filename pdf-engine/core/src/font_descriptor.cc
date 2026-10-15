// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

#include "font_descriptor.hh"
#include "util.hh"
#include <assert.h>

using namespace std;


static optional<int> getFontWeight(QPDFObjectHandle fontDescriptorDictionary) {
    // ISO 32000-2, section 9.8.1 General
    // /FontWeight used to be a number, but is an integer
    double w = 0;
    if (!fontDescriptorDictionary.getKeyIfDict("/FontWeight").getValueAsNumber(w)) {
        return nullopt;
    }
    // Valid values are integers in the closed interval [100, 900]
    if (!(w >= 100 && w <= 900)) {
        return nullopt;
    }
    // Just truncate
    const auto weight = static_cast<int>(w / 100);
    return weight * 100;
}


optional<pdf_font_descriptor> parseFontDescriptor(pdf_font_subtype subtype,
                                                  QPDFObjectHandle fontDictionary) {
    if (subtype == PDF_FONT_SUBTYPE_TYPE0) {
        const auto descendantFontsArray = fontDictionary.getKeyIfDict("/DescendantFonts");
        if (!descendantFontsArray.isArray() || descendantFontsArray.getArrayNItems() <= 0) {
            return nullopt;
        }
        const auto descendantFontDict = descendantFontsArray.getArrayItem(0);
        if (!descendantFontDict.isDictionary()) {
            return nullopt;
        }
        string descendantSubtypeString;
        if (!descendantFontDict.getKeyIfDict("/Subtype").getValueAsName(descendantSubtypeString)) {
            return nullopt;
        }
        pdf_font_subtype descendantSubtype;
        if (descendantSubtypeString == "/CIDFontType0") {
            descendantSubtype = PDF_FONT_SUBTYPE_CID_FONT_TYPE0;
        } else if (descendantSubtypeString == "/CIDFontType2") {
            descendantSubtype = PDF_FONT_SUBTYPE_CID_FONT_TYPE2;
        } else {
            return nullopt;
        }
        // Recursing here is OK: descendantSubtype is not PDF_FONT_SUBTYPE_TYPE0 so no risk of
        // infinite recursion
        auto descendantDesc = parseFontDescriptor(descendantSubtype, descendantFontDict);
        // Remember the descendant's subtype
        if (descendantDesc) {
            descendantDesc->descendantSubtype = descendantSubtype;
        }
        return descendantDesc;
    }

    const auto fontDescriptorDictionary = fontDictionary.getKeyIfDict("/FontDescriptor");
    if (!fontDescriptorDictionary.isDictionary()) {
        return nullopt;
    }
    if (!fontDescriptorDictionary.getKeyIfDict("/Type").isNameAndEquals("/FontDescriptor")) {
        return nullopt;
    }
    const auto fontNameKey = fontDescriptorDictionary.getKeyIfDict("/FontName");
    string fontName;
    if (!fontNameKey.getValueAsName(fontName)) {
        return nullopt;
    }
    int flags = 0;
    if (!fontDescriptorDictionary.getKeyIfDict("/Flags").getValueAsInt(flags)) {
        return nullopt;
    }
    optional<string> fontFamily = getUTF8String(fontDescriptorDictionary, "/FontFamily");
    const auto program = parseFontProgram(subtype, fontDescriptorDictionary);
    return make_optional(pdf_font_descriptor{
        .name = fontName,
        .family = fontFamily,
        .weight = getFontWeight(fontDescriptorDictionary),
        .flags = static_cast<uint32_t>(flags),
        .program = program,
    });
}


const char *pdf_font_descriptor_get_name(const struct pdf_font_descriptor *d) {
    assert(d != nullptr);
    return d->name.c_str();
}


const char *pdf_font_descriptor_get_family(const struct pdf_font_descriptor *d) {
    assert(d != nullptr);
    if (d->family) {
        return d->family->c_str();
    }
    return nullptr;
}


const int *pdf_font_descriptor_get_weight(const struct pdf_font_descriptor *d) {
    assert(d != nullptr);
    if (d->weight) {
        return &*d->weight;
    }
    return nullptr;
}


uint32_t pdf_font_descriptor_get_flags(const struct pdf_font_descriptor *d) {
    assert(d != nullptr);
    return d->flags;
}


const struct pdf_font_program *
pdf_font_descriptor_get_program(const struct pdf_font_descriptor *d) {
    assert(d != nullptr);
    if (d->program) {
        return &*d->program;
    }
    return nullptr;
}


const pdf_font_subtype *pdf_font_descriptor_get_descendant_subtype(const pdf_font_descriptor *d) {
    assert(d != nullptr);
    if (d->descendantSubtype) {
        return &*d->descendantSubtype;
    }
    return nullptr;
}
