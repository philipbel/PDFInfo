// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

#pragma once


#ifdef __cplusplus
extern "C" {
#endif


enum pdf_page_paper_size {
    PDF_PAGE_PAPER_SIZE_CUSTOM = 0,
    PDF_PAGE_PAPER_SIZE_A4,
    PDF_PAGE_PAPER_SIZE_LETTER,
};


enum pdf_page_size_orientation {
    PDF_PAGE_SIZE_ORIENTATION_PORTRAIT = 0,
    PDF_PAGE_SIZE_ORIENTATION_LANDSCAPE,
};


struct pdf_page_size {
    double width;
    double height;
    enum pdf_page_paper_size paper_size;
    enum pdf_page_size_orientation orientation;
};


#ifdef __cplusplus
}
#endif
