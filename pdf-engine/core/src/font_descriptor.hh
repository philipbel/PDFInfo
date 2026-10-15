// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

#pragma once

#include "font_program.hh"
#include <optional>
#include <pdf-engine/font.h>
#include <pdf-engine/font_descriptor.h>
#include <qpdf/QPDFObjectHandle.hh>
#include <string>


struct pdf_font_descriptor {
    std::string name;
    std::optional<std::string> family;
    std::optional<int> weight;
    uint32_t flags;
    std::optional<pdf_font_program> program;
    // For Type0 fonts with descendant fonts.
    // See ISO 32000-2, section 9.7.6 Type 0 font dictionaries
    std::optional<pdf_font_subtype> descendantSubtype;
};


extern std::optional<pdf_font_descriptor> parseFontDescriptor(pdf_font_subtype subtype,
                                                              QPDFObjectHandle fontDictionary);
