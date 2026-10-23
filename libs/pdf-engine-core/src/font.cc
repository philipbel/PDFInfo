// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

#include "font.hh"
#include <algorithm>
#include <assert.h>
#include <qpdf/ObjectHandle.hh>
#include <qpdf/QPDFPageDocumentHelper.hh>
#include <regex>
#include <unordered_set>

using namespace std;


static const unordered_set<string> cmapNames{
    // Chinese (Simplified)
    "GB-EUC-H",      // Microsoft Code Page 936 (lfCharSet 0x86), GB 2312-80 character set, EUC-CN
                     // encoding
    "GB-EUC-V",      // Vertical version of GB-EUC-H
    "GBpc-EUC-H",    // Mac OS, GB 2312-80 character set, EUC-CN encoding, Script Manager code 19
    "GBpc-EUC-V",    // Vertical version of GBpc-EUC-H
    "GBK-EUC-H",     // Microsoft Code Page 936 (lfCharSet 0x86), GBK character set, GBK encoding
    "GBK-EUC-V",     // Vertical version of GBK-EUC-H
    "GBKp-EUC-H",    // Same as GBK-EUC-H but replaces half-width Latin characters with proportional
                     // forms and maps
                     // character code 0x24 to a dollar sign ($) instead of a yuan symbol (¥)
    "GBKp-EUC-V",    // Vertical version of GBKp-EUC-H
    "GBK2K-H",       // GB 18030-2000 character set, mixed 1-, 2-, and 4-byte encoding
    "GBK2K-V",       // Vertical version of GBK2K-H
    "UniGB-UCS2-H",  // Unicode (UCS-2) encoding for the Adobe-GB1 character collection
    "UniGB-UCS2-V",  // Vertical version of UniGB-UCS2-H
    "UniGB-UTF16-H", // Unicode (UTF-16BE) encoding for the Adobe-GB1 character collection; contains
                     // mappings for all
                     // characters in the GB18030-2000 character set
    "UniGB-UTF16-V", // Vertical version of UniGB-UTF16-H
    // Chinese (Traditional)
    "B5pc-H",        // Mac OS, Big Five character set, Big Five encoding, Script Manager code 2
    "B5pc-V",        // Vertical version of B5pc-H
    "HKscs-B5-H",    // Hong Kong SCS, an extension to the Big Five character set and encoding
    "HKscs-B5-V",    // Vertical version of HKscs-B5-H
    "ETen-B5-H",     // Microsoft Code Page 950 (lfCharSet 0x88), Big Five character set with ETen
                     // extensions
    "ETen-B5-V",     // Vertical version of ETen-B5-H
    "ETenms-B5-H",   // Same as ETen-B5-H but replaces half-width Latin characters with proportional
                     // forms
    "ETenms-B5-V",   // Vertical version of ETenms-B5-H
    "CNS-EUC-H",     // CNS 11643-1992 character set, EUC-TW encoding
    "CNS-EUC-V",     // Vertical version of CNS-EUC-H
    "UniCNS-UCS2-H", // Unicode (UCS-2) encoding for the Adobe-CNS1-6 character collection
    "UniCNS-UCS2-V", // Vertical version of UniCNS-UCS2-H
    "UniCNS-UTF16-H", // Unicode (UTF-16BE) encoding for the Adobe-CNS1-6 character collection;
                      // contains mappings for
    // all the characters in the HKSCS-2001 character set and contains both 2- and 4-byte character
    // codes
    "UniCNS-UTF16-V", // Vertical version of UniCNS-UTF16-H
    // Japanese
    "83pv-RKSJ-H",   // Mac OS, JIS X 0208 character set with KanjiTalk6 extensions, Shift-JIS
                     // encoding, Script Manager
                     // code 1
    "90ms-RKSJ-H",   // Microsoft Code Page 932 (lfCharSet 0x80), JIS X 0208 character set with NEC
                     // and IBM® extensions
    "90ms-RKSJ-V",   // Vertical version of 90ms-RKSJ-H
    "90msp-RKSJ-H",  // Same as 90ms-RKSJ-H but replaces half-width Latin characters with
                     // proportional forms
    "90msp-RKSJ-V",  // Vertical version of 90msp-RKSJ-H
    "90pv-RKSJ-H",   // Mac OS, JIS X 0208 character set with KanjiTalk7 extensions, Shift-JIS
                     // encoding, Script Manager
                     // code 1
    "Add-RKSJ-H",    // JIS X 0208 character set with Fujitsu FMR extensions, Shift-JIS encoding
    "Add-RKSJ-V",    // Vertical version of Add-RKSJ-H
    "EUC-H",         // JIS X 0208 character set, EUC-JP encoding
    "EUC-V",         // Vertical version of EUC-H
    "Ext-RKSJ-H",    // JIS C 6226 (JIS78) character set with NEC extensions, Shift-JIS encoding
    "Ext-RKSJ-V",    // Vertical version of Ext-RKSJ-H
    "H",             // JIS X 0208 character set, ISO-2022-JP encoding
    "V",             // Vertical version of H
    "UniJIS-UCS2-H", // Unicode (UCS-2) encoding for the Adobe-Japan1 character collection
    "UniJIS-UCS2-V", // Vertical version of UniJIS-UCS2-H
    "UniJIS-UCS2-HW-H", // Same as UniJIS-UCS2-H but replaces proportional Latin characters with
                        // half-width forms
    "UniJIS-UCS2-HW-V", // Vertical version of UniJIS-UCS2-HW-H
    "UniJIS-UTF16-H",   // Unicode (UTF-16BE) encoding for the Adobe-Japan1 character collection;
                        // contains mappings for
                        // all characters in the JIS X 0213:1000 character set
    "UniJIS-UTF16-V",   // Vertical version of UniJIS-UTF16-H
    // Korean
    "KSC-EUC-H",      // KS X 1001:1992 character set, EUC-KR encoding
    "KSC-EUC-V",      // Vertical version of KSC-EUC-H
    "KSCms-UHC-H",    // Microsoft Code Page 949 (lfCharSet 0x81), KS X 1001:1992 character set plus
                      // 8822 additional
                      // hangul, Unified Hangul Code (UHC) encoding
    "KSCms-UHC-V",    // Vertical version of KSCms-UHC-H
    "KSCms-UHC-HW-H", // Same as KSCms-UHC-H but replaces proportional Latin characters with
                      // half-width forms
    "KSCms-UHC-HW-V", // Vertical version of KSCms-UHC-HW-H
    "KSCpc-EUC-H", // Mac OS, KS X 1001:1992 character set with Mac OS KH extensions, Script Manager
                   // Code 3
    "UniKS-UCS2-H",  // Unicode (UCS-2) encoding for the Adobe-Korea1 character collection
    "UniKS-UCS2-V",  // Vertical version of UniKS-UCS2-H
    "UniKS-UTF16-H", // Unicode (UTF-16BE) encoding for the Adobe-Korea1 character collection
    "UniKS-UTF16-V", // Vertical version of UniKS-UTF16-H
    // Generic
    "Identity-H", // The horizontal identity mapping for 2-byte CIDs; may be used with CIDFonts
                  // using any Registry,
    // Ordering, and Supplement values. It maps 2-byte character codes ranging from 0 to 65,535 to
    // the
    // same 2-byte CID value, interpreted high-order byte first.
    "Identity-V", // Vertical version of Identity-H. The mapping is the same as for Identity-H.
};


static const auto subsetPrefixRegex = regex("^[A-Z]{6}\\+");


static optional<pdf_font_subtype> getFontSubtype(QPDFObjectHandle fontDictionary) {
    string subtypeValue;
    if (!fontDictionary.getKey("/Subtype").getValueAsName(subtypeValue)) {
        return nullopt;
    }
    if (subtypeValue == "/Type0") {
        return PDF_FONT_SUBTYPE_TYPE0;
    } else if (subtypeValue == "/Type1") {
        return PDF_FONT_SUBTYPE_TYPE1;
    } else if (subtypeValue == "/MMType1") {
        return PDF_FONT_SUBTYPE_MM_TYPE1;
    } else if (subtypeValue == "/Type3") {
        return PDF_FONT_SUBTYPE_TYPE3;
    } else if (subtypeValue == "/TrueType") {
        return PDF_FONT_SUBTYPE_TRUETYPE;
    } else if (subtypeValue == "/CIDFontType0") {
        return PDF_FONT_SUBTYPE_CID_FONT_TYPE0;
    } else if (subtypeValue == "/CIDFontType2") {
        return PDF_FONT_SUBTYPE_CID_FONT_TYPE2;
    }
    // TODO: Warn
    return nullopt;
}


static tuple<string, optional<string>> splitFontNameCmap(const string &name) {
    // TODO: Store the suffixies in cmapNames instead of doing this
    vector<string> suffixes;
    ranges::copy_if(
        cmapNames, back_inserter(suffixes), [&](auto const &s) { return name.ends_with("-" + s); });
    ranges::sort(suffixes, ranges::greater{}, &string::size);

    if (suffixes.empty()) {
        return {name, nullopt};
    }
    const auto &cmapName = suffixes.front();
    auto displayName = name.substr(0, name.size() - cmapName.size() - 1); // -1 for the "-"
    return {displayName, cmapName};
}


static string stripLeadingSlash(const string &s) {
    if (!s.empty() && s[0] == '/') {
        return s.substr(1);
    }
    return s;
}


static optional<string> getFontBaseFont(QPDFObjectHandle fontDictionary) {
    string baseFont;
    if (fontDictionary.getKey("/BaseFont").getValueAsName(baseFont)) {
        return stripLeadingSlash(baseFont);
    }
    return nullopt;
}


static tuple<string, bool> getFontDisplayNameSubset(const string &name) {
    smatch words;
    if (regex_search(name, words, subsetPrefixRegex)) {
        return {words.suffix().str(), true};
    }
    return {name, false};
}


static pdf_font_display_type getDisplayType(pdf_font_subtype subtype,
                                            const optional<pdf_font_descriptor> &descriptor) {
    // See
    // https://gitlab.freedesktop.org/poppler/poppler/-/blob/master/poppler/GfxFont.cc#L288

    switch (subtype) {
    case PDF_FONT_SUBTYPE_TYPE0:
        if (!descriptor || !descriptor->descendantSubtype) {
            return PDF_FONT_DISPLAY_TYPE_TYPE0;
        }
        return getDisplayType(*descriptor->descendantSubtype, descriptor);
    case PDF_FONT_SUBTYPE_TYPE1: // fallthrough
    case PDF_FONT_SUBTYPE_MM_TYPE1:
        if (!descriptor || !descriptor->program) {
            return PDF_FONT_DISPLAY_TYPE_TYPE1;
        }
        switch (descriptor->program->kind) {
        case PDF_FONT_PROGRAM_KIND_TYPE1C:
            return PDF_FONT_DISPLAY_TYPE_TYPE1C;
        case PDF_FONT_PROGRAM_KIND_OPEN_TYPE:
            return PDF_FONT_DISPLAY_TYPE_TYPE1C_OPEN_TYPE;
        case PDF_FONT_PROGRAM_KIND_TYPE1: // fallthrough
        default:
            return PDF_FONT_DISPLAY_TYPE_TYPE1;
        }
    case PDF_FONT_SUBTYPE_TYPE3:
        return PDF_FONT_DISPLAY_TYPE_TYPE3;
    case PDF_FONT_SUBTYPE_TRUETYPE:
        if (!descriptor || !descriptor->program) {
            return PDF_FONT_DISPLAY_TYPE_TRUE_TYPE;
        }
        switch (descriptor->program->kind) {
        case PDF_FONT_PROGRAM_KIND_OPEN_TYPE:
            return PDF_FONT_DISPLAY_TYPE_TRUE_TYPE_OPEN_TYPE;
        default:
            return PDF_FONT_DISPLAY_TYPE_TRUE_TYPE;
        }
    case PDF_FONT_SUBTYPE_CID_FONT_TYPE0:
        if (!descriptor || !descriptor->program) {
            return PDF_FONT_DISPLAY_TYPE_CID_TYPE0;
        }
        switch (descriptor->program->kind) {
        case PDF_FONT_PROGRAM_KIND_CID_FONT_TYPE0C:
            return PDF_FONT_DISPLAY_TYPE_CID_TYPE0C;
        case PDF_FONT_PROGRAM_KIND_OPEN_TYPE:
            return PDF_FONT_DISPLAY_TYPE_CID_TYPE0C_OPEN_TYPE;
        default:
            return PDF_FONT_DISPLAY_TYPE_CID_TYPE0;
        }
    case PDF_FONT_SUBTYPE_CID_FONT_TYPE2:
        if (!descriptor || !descriptor->program) {
            return PDF_FONT_DISPLAY_TYPE_CID_TRUE_TYPE;
        }
        switch (descriptor->program->kind) {
        case PDF_FONT_PROGRAM_KIND_OPEN_TYPE:
            return PDF_FONT_DISPLAY_TYPE_CID_TRUE_TYPE_OPEN_TYPE;
        case PDF_FONT_PROGRAM_KIND_TRUE_TYPE:
        default:
            return PDF_FONT_DISPLAY_TYPE_CID_TRUE_TYPE;
        }
    }

    assert(false && "Should never be reached");
    return PDF_FONT_DISPLAY_TYPE_TYPE0;
}


shared_ptr<pdf_font> parseFontDictionary(const string &resourceName,
                                         QPDFObjectHandle fontDictionary) {
    if (!fontDictionary.isDictionary()) {
        // TODO: Warn
        return nullptr;
    }
    if (!fontDictionary.getKey("/Type").isNameAndEquals("/Font")) {
        // TODO: Warn
        return nullptr;
    }

    const auto subtype = getFontSubtype(fontDictionary);
    if (!subtype) {
        return nullptr;
    }

    const auto objGen = fontDictionary.getObjGen();
    const uint64_t objectID = (uint64_t(objGen.getObj()) << 32) | uint32_t(objGen.getGen());

    string baseFont;
    string displayName;
    bool isSubset;

    if (auto b = getFontBaseFont(fontDictionary)) {
        baseFont = b.value();
        tie(displayName, isSubset) = getFontDisplayNameSubset(b.value());
    } else {
        // Type3 fonts have no BaseFont, see 9.6.4 Type 3 fonts. Name is optional
        if (fontDictionary.getKey("/Name").getValueAsName(baseFont)) {
            baseFont = stripLeadingSlash(baseFont);
            tie(displayName, isSubset) = getFontDisplayNameSubset(baseFont);
        } else {
            // Fallback to using the resource name
            baseFont = resourceName;
            isSubset = false;
            displayName = baseFont;
        }
    }
    optional<string> cmapName;
    if (subtype == PDF_FONT_SUBTYPE_TYPE0) {
        tie(displayName, cmapName) = splitFontNameCmap(displayName);
    }

    auto font = make_shared<pdf_font>();
    font->id = objectID;
    font->displayName = displayName;
    font->baseFont = baseFont;
    font->subtype = *subtype;
    font->isSubset = isSubset;
    font->cmapName = cmapName;
    font->descriptor = parseFontDescriptor(*subtype, fontDictionary);
    font->displayType = getDisplayType(*subtype, font->descriptor);
    return font;
}


vector<shared_ptr<pdf_font>> parseDocumentFonts(QPDF &qpdf) {
    vector<shared_ptr<pdf_font>> fonts;
    QPDFObjGen::set visitedObjects;

    auto &helper = QPDFPageDocumentHelper::get(qpdf);
    for (auto &page : helper.getAllPages()) {
        auto resources = page.getAttribute("/Resources", false);
        if (resources.isNull()) {
            continue;
        }
        if (!resources.isDictionary()) {
            // TODO: Warn
            continue;
        }
        if (!visitedObjects.add(resources.getObjGen())) {
            continue;
        }

        auto pageFontDictionary = resources.getKey("/Font");
        if (pageFontDictionary.isNull()) {
            continue;
        }
        if (!pageFontDictionary.isDictionary()) {
            // TODO: Warn
            continue;
        }

        if (!visitedObjects.add(pageFontDictionary.getObjGen())) {
            continue;
        }

        for (const auto &[resourceName, fontDictionary] : pageFontDictionary.ditems()) {
            if (!visitedObjects.add(fontDictionary)) {
                continue;
            }

            if (const auto font =
                    parseFontDictionary(stripLeadingSlash(resourceName), fontDictionary)) {
                fonts.push_back(font);
            }
        }
    }
    return fonts;
}


uint64_t pdf_font_get_id(const pdf_font *f) {
    assert(f != nullptr);
    return f->id;
}


pdf_font_subtype pdf_font_get_subtype(const pdf_font *f) {
    assert(f != nullptr);
    return f->subtype;
}


const char *pdf_font_get_display_name(const pdf_font *f) {
    assert(f != nullptr);
    return f->displayName.c_str();
}


const char *pdf_font_get_base_font(const pdf_font *f) {
    assert(f != nullptr);
    return f->baseFont.c_str();
}


bool pdf_font_is_subset(const pdf_font *f) {
    assert(f != nullptr);
    return f->isSubset;
}


bool pdf_font_is_embedded(const pdf_font *f) {
    assert(f != nullptr);
    return f->descriptor && f->descriptor->program;
}


const char *pdf_font_get_cmap_name(const pdf_font *f) {
    assert(f != nullptr);
    if (f->cmapName) {
        return f->cmapName->c_str();
    }
    return nullptr;
}


const pdf_font_descriptor *pdf_font_get_descriptor(const pdf_font *f) {
    assert(f != nullptr);
    if (f->descriptor) {
        return &*f->descriptor;
    }
    return nullptr;
}


pdf_font_display_type pdf_font_get_display_type(const struct pdf_font *f) {
    assert(f != nullptr);
    return f->displayType;
}
