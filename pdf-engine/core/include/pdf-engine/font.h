// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

#pragma once

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif


struct pdf_font;
struct pdf_font_descriptor;

enum pdf_font_subtype {
    PDF_FONT_SUBTYPE_TYPE0 = 0,
    PDF_FONT_SUBTYPE_TYPE1,
    PDF_FONT_SUBTYPE_MM_TYPE1,
    PDF_FONT_SUBTYPE_TYPE3,
    PDF_FONT_SUBTYPE_TRUETYPE,
    PDF_FONT_SUBTYPE_CID_FONT_TYPE0,
    PDF_FONT_SUBTYPE_CID_FONT_TYPE2,
};


// The "type" of the font used for display purposes. Computed from the font's
// `subtype' and program's kind.
enum pdf_font_display_type {
    PDF_FONT_DISPLAY_TYPE_TYPE0 = 0,
    PDF_FONT_DISPLAY_TYPE_TYPE1,
    PDF_FONT_DISPLAY_TYPE_TYPE1C,
    PDF_FONT_DISPLAY_TYPE_TYPE1C_OPEN_TYPE,
    PDF_FONT_DISPLAY_TYPE_TYPE3,
    PDF_FONT_DISPLAY_TYPE_TRUE_TYPE,
    PDF_FONT_DISPLAY_TYPE_TRUE_TYPE_OPEN_TYPE,
    PDF_FONT_DISPLAY_TYPE_CID_TYPE0,
    PDF_FONT_DISPLAY_TYPE_CID_TYPE0C,
    PDF_FONT_DISPLAY_TYPE_CID_TYPE0C_OPEN_TYPE,
    PDF_FONT_DISPLAY_TYPE_CID_TRUE_TYPE,
    PDF_FONT_DISPLAY_TYPE_CID_TRUE_TYPE_OPEN_TYPE,
};


extern uint64_t pdf_font_get_id(const struct pdf_font *f);
extern enum pdf_font_subtype pdf_font_get_subtype(const struct pdf_font *f);
extern const char *pdf_font_get_display_name(const struct pdf_font *f);
extern const char *pdf_font_get_base_font(const struct pdf_font *f);
extern bool pdf_font_is_subset(const struct pdf_font *f);
extern bool pdf_font_is_embedded(const struct pdf_font *f);
extern const char *pdf_font_get_cmap_name(const struct pdf_font *f);
extern const struct pdf_font_descriptor *pdf_font_get_descriptor(const struct pdf_font *f);
extern enum pdf_font_display_type pdf_font_get_display_type(const struct pdf_font *f);


#ifdef __cplusplus
}
#endif
