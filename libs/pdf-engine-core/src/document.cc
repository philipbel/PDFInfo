// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT


#include "document.hh"
#include "page_size.hh"
#include <assert.h>
#include <pdf-engine/document.h>
#include <qpdf/QPDF.hh>
#include <qpdf/QPDFPageDocumentHelper.hh>

using namespace std;


struct pdf_document *pdf_document_open(const uint8_t *buffer, size_t size) {
    if (buffer == nullptr || size == 0) {
        return nullptr;
    }

    try {
        auto doc = make_unique<pdf_document>();
        auto qpdf = QPDF::create();
        qpdf->processMemoryFile("pdf-engine-core-file", (const char *)buffer, size, nullptr);

        // TODO: Report warnings

        auto pages = QPDFPageDocumentHelper::get(*qpdf).getAllPages();

        doc->fonts = parseDocumentFonts(*qpdf);

        doc->page_count = pages.size();

        const auto &v = qpdf->getVersionAsPDFVersion();
        doc->version = pdf_document_version{
            .major = uint32_t(v.getMajor()),
            .minor = uint32_t(v.getMinor()),
            .extension = uint32_t(v.getExtensionLevel()),
        };
        doc->metadata = parseDocumentMetadata(*qpdf);
        doc->page_size = getDocumentPageSize(pages);
        return doc.release();
    } catch (const exception &) {
        // TODO: Warn
        return nullptr;
    }
}


void pdf_document_free(struct pdf_document *d) {
    delete d;
}


pdf_document_version pdf_document_get_version(const pdf_document *d) {
    assert(d != nullptr);
    return d->version;
}


const pdf_document_metadata *pdf_document_get_metadata(const pdf_document *d) {
    assert(d != nullptr);
    if (d->metadata) {
        return &*d->metadata;
    }
    return nullptr;
}


size_t pdf_document_get_page_count(const pdf_document *d) {
    assert(d != nullptr);
    return d->page_count;
}


size_t pdf_document_get_font_count(const pdf_document *d) {
    assert(d != nullptr);
    return d->fonts.size();
}


const pdf_font *pdf_document_get_font(const pdf_document *d, size_t n) {
    assert(d != nullptr);
    if (n >= d->fonts.size()) {
        return nullptr;
    }
    return d->fonts[n].get();
}


const pdf_page_size *pdf_document_get_page_size(const pdf_document *d) {
    assert(d != nullptr);
    if (!d->page_size) {
        return nullptr;
    }
    return &*d->page_size;
}
