// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT


#pragma once

#include "font.hh"
#include "metadata.hh"
#include <pdf-engine/pdf-engine.h>
#include <vector>


struct pdf_document {
    std::vector<std::shared_ptr<pdf_font>> fonts;
    size_t page_count;
    pdf_document_version version;
    std::optional<pdf_document_metadata> metadata;
    std::optional<pdf_page_size> page_size;
};
