// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use crate::ffi;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum PaperSize {
    Custom,
    A4,
    Letter,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum PageOrientation {
    Portrait,
    Landscape,
}

#[derive(Debug)]
pub struct PageSize {
    // Width in points
    pub width: f64,
    // Height in points
    pub height: f64,
    pub paper_size: PaperSize,
    pub orientation: PageOrientation,
}

impl From<&ffi::pdf_page_size> for PageSize {
    fn from(ps: &ffi::pdf_page_size) -> Self {
        PageSize {
            width: ps.width,
            height: ps.height,
            paper_size: match ps.paper_size {
                ffi::PDF_PAGE_PAPER_SIZE_A4 => PaperSize::A4,
                ffi::PDF_PAGE_PAPER_SIZE_LETTER => PaperSize::Letter,
                _ => PaperSize::Custom,
            },
            orientation: match ps.orientation {
                ffi::PDF_PAGE_SIZE_ORIENTATION_LANDSCAPE => PageOrientation::Landscape,
                _ => PageOrientation::Portrait,
            },
        }
    }
}
