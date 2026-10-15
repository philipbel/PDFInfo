// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT


#include "page_size.hh"
#include <cmath>
#include <tuple>

using namespace std;


static const double a4_width_pt = 595.276;
static const double a4_height_pt = 841.890;
static const double letter_width_pt = 612;
static const double letter_height_pt = 792;
static const double epsilon_pt = 1;


static tuple<pdf_page_paper_size, pdf_page_size_orientation>
getPaperSizeAndOrientation(double width, double height) {
    pdf_page_size_orientation orientation;
    if (width <= height) {
        orientation = PDF_PAGE_SIZE_ORIENTATION_PORTRAIT;
    } else {
        swap(width, height);
        orientation = PDF_PAGE_SIZE_ORIENTATION_LANDSCAPE;
    }
    if (abs(width - a4_width_pt) < epsilon_pt && abs(height - a4_height_pt) < epsilon_pt) {
        return make_tuple(PDF_PAGE_PAPER_SIZE_A4, orientation);
    } else if (abs(width - letter_width_pt) < epsilon_pt
               && abs(height - letter_height_pt) < epsilon_pt) {
        return make_tuple(PDF_PAGE_PAPER_SIZE_LETTER, orientation);
    } else {
        return make_tuple(PDF_PAGE_PAPER_SIZE_CUSTOM, orientation);
    }
}


optional<pdf_page_size> getDocumentPageSize(vector<QPDFPageObjectHelper> &pages) {
    if (pages.empty()) {
        return nullopt;
    }
    auto &page = pages.front();
    const auto r = page.getCropBox().getArrayAsRectangle(); // falls back to MediaBox
    double w = abs(r.urx - r.llx);
    double h = abs(r.ury - r.lly);
    if (w <= 0 || h <= 0) {
        return nullopt;
    }

    const auto rotationAttribute = page.getAttribute("/Rotate", false);
    if (rotationAttribute.isInteger()) {
        const int rotation = ((rotationAttribute.getIntValueAsInt() % 360) + 360) % 360;
        if (rotation == 90 || rotation == 270) {
            swap(w, h);
        }
    }

    auto [paper_size, orientation] = getPaperSizeAndOrientation(w, h);
    return pdf_page_size{
        .width = w,
        .height = h,
        .paper_size = paper_size,
        .orientation = orientation,
    };
}
