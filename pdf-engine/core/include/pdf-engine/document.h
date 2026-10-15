// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

#pragma once

#include "page_size.h"
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif


struct pdf_document;


struct pdf_document_version {
    uint32_t major;
    uint32_t minor;
    uint32_t extension;
};


extern struct pdf_document *pdf_document_open(const uint8_t *buffer, size_t size);
extern void pdf_document_free(struct pdf_document *d);
extern struct pdf_document_version pdf_document_get_version(const struct pdf_document *d);
extern const struct pdf_document_metadata *pdf_document_get_metadata(const struct pdf_document *d);
extern size_t pdf_document_get_page_count(const struct pdf_document *d);
extern size_t pdf_document_get_font_count(const struct pdf_document *d);
extern const struct pdf_font *pdf_document_get_font(const struct pdf_document *d, size_t n);
extern const struct pdf_page_size *pdf_document_get_page_size(const struct pdf_document *d);


#ifdef __cplusplus
}
#endif
