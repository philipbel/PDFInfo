// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

#pragma once

#include "font.h"
#include "font_program.h"
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif


struct pdf_font_descriptor;


// See ISO 32000-2, 9.8.2 Font descriptor flags
// Note: the spec lists the bits from 1
enum pdf_font_descriptor_flags {
    PDF_FONT_DESCRIPTOR_FLAG_FIXED_PITCH = 1 << (1 - 1),
    PDF_FONT_DESCRIPTOR_FLAG_SERIF = 1 << (2 - 1),
    PDF_FONT_DESCRIPTOR_FLAG_SYMBOLIC = 1 << (3 - 1),
    PDF_FONT_DESCRIPTOR_FLAG_SCRIPT = 1 << (4 - 1),
    PDF_FONT_DESCRIPTOR_FLAG_NON_SYMBOLIC = 1 << (6 - 1),
    PDF_FONT_DESCRIPTOR_FLAG_ITALIC = 1 << (7 - 1),
    PDF_FONT_DESCRIPTOR_FLAG_ALL_CAP = 1 << (17 - 1),
    PDF_FONT_DESCRIPTOR_FLAG_SMALL_CAP = 1 << (18 - 1),
    PDF_FONT_DESCRIPTOR_FLAG_FORCE_BOLD = 1 << (19 - 1),
};


extern const char *pdf_font_descriptor_get_name(const struct pdf_font_descriptor *d);
extern const char *pdf_font_descriptor_get_family(const struct pdf_font_descriptor *d);
extern const int *pdf_font_descriptor_get_weight(const struct pdf_font_descriptor *d);
extern uint32_t pdf_font_descriptor_get_flags(const struct pdf_font_descriptor *d);
extern const struct pdf_font_program *
pdf_font_descriptor_get_program(const struct pdf_font_descriptor *d);
extern const enum pdf_font_subtype *
pdf_font_descriptor_get_descendant_subtype(const struct pdf_font_descriptor *d);


#ifdef __cplusplus
}
#endif
