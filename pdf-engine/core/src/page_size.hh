// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

#pragma once

#include <optional>
#include <pdf-engine/page_size.h>
#include <qpdf/QPDFPageObjectHelper.hh>
#include <vector>

extern std::optional<pdf_page_size> getDocumentPageSize(std::vector<QPDFPageObjectHelper> &pages);
