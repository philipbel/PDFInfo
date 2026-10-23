// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif


struct pdf_font_program;


enum pdf_font_program_kind {
    // FontFile, A stream containing a Type 1 font program
    PDF_FONT_PROGRAM_KIND_TYPE1 = 0,
    // FontFile2, A stream containing a TrueType font program
    PDF_FONT_PROGRAM_KIND_TRUE_TYPE,
    // FontFile3, Subtype Type1C: Type 1–equivalent font program represented in the Compact Font
    // Format (CFF)
    PDF_FONT_PROGRAM_KIND_TYPE1C,
    // FontFile3, Subtype CIDFontType0C: Type 0 CIDFont program represented in the Compact Font
    // Format (CFF)
    PDF_FONT_PROGRAM_KIND_CID_FONT_TYPE0C,
    // FontFile3, Subtype OpenType: OpenType font program
    // - A TrueType font dictionary or a CIDFontType2 CIDFont dictionary, if the embedded font
    //   program contains a "glyf" table
    // - A CIDFontType0 CIDFont dictionary, if the embedded font program contains a "CFF " table
    //   with a Top DICT that uses CIDFont operators (this is equivalent to subtype CIDFontType0C)
    // - A Type1 font dictionary or CIDFontType0 CIDFont dictionary, if the embedded font program
    //   contains a "CFF " table without CIDFont operators
    PDF_FONT_PROGRAM_KIND_OPEN_TYPE,
};


extern enum pdf_font_program_kind pdf_font_program_get_kind(const struct pdf_font_program *p);
extern size_t pdf_font_program_get_size(const struct pdf_font_program *p);
extern const uint8_t *pdf_font_program_get_data(const struct pdf_font_program *p);


#ifdef __cplusplus
}
#endif
