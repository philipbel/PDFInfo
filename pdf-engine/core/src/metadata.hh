// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

#pragma once

#include <pdf-engine/pdf-engine.h>

#include <qpdf/QPDF.hh>

#include <optional>
#include <string>
#include <vector>


struct pdf_document_metadata {
    std::optional<std::string> title;
    std::optional<std::string> author;
    std::optional<std::string> subject;
    std::vector<std::string> keywords;
    std::optional<std::string> creator;
    std::optional<std::string> producer;
    std::optional<int64_t> creation_date;
    std::optional<int64_t> mod_date;
    std::optional<bool> trapped;
};


extern std::optional<pdf_document_metadata> parseDocumentMetadata(QPDF &qpdf);
