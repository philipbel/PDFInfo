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

struct pdf_document_metadata;


extern const char *pdf_document_metadata_get_title(const struct pdf_document_metadata *m);
extern const char *pdf_document_metadata_get_author(const struct pdf_document_metadata *m);
extern const char *pdf_document_metadata_get_subject(const struct pdf_document_metadata *m);
extern size_t pdf_document_metadata_get_keyword_count(const struct pdf_document_metadata *m);
extern const char *pdf_document_metadata_get_keyword(const struct pdf_document_metadata *m,
                                                     size_t n);
extern const char *pdf_document_metadata_get_creator(const struct pdf_document_metadata *m);
extern const char *pdf_document_metadata_get_producer(const struct pdf_document_metadata *m);
extern const int64_t *
pdf_document_metadata_get_creation_date(const struct pdf_document_metadata *m);
extern const int64_t *pdf_document_metadata_get_mod_date(const struct pdf_document_metadata *m);
extern const bool *pdf_document_metadata_get_trapped(const struct pdf_document_metadata *m);


#ifdef __cplusplus
}
#endif
