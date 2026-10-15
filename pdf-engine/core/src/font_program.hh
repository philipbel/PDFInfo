// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

#pragma once

#include <memory>
#include <optional>
#include <pdf-engine/font.h>
#include <pdf-engine/font_program.h>
#include <qpdf/Buffer.hh>
#include <qpdf/QPDFObjectHandle.hh>


struct pdf_font_program {
    pdf_font_program_kind kind;
    std::shared_ptr<Buffer> data;
};


extern std::optional<pdf_font_program> parseFontProgram(pdf_font_subtype subtype,
                                                        QPDFObjectHandle fontDescriptorDictionary);
