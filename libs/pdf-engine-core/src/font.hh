// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT


#pragma once

#include "font_descriptor.hh"
#include <memory>
#include <optional>
#include <pdf-engine/font.h>
#include <qpdf/QPDF.hh>
#include <stdint.h>
#include <string>
#include <vector>


struct pdf_font {
    uint64_t id;
    std::string displayName;
    std::string baseFont;
    pdf_font_subtype subtype;
    bool isSubset;
    std::optional<std::string> cmapName;
    std::optional<pdf_font_descriptor> descriptor;
    pdf_font_display_type displayType;
};


extern std::vector<std::shared_ptr<pdf_font>> parseDocumentFonts(QPDF &qpdf);
