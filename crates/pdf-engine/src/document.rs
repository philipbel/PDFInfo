// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::fmt::Debug;
use std::ptr::NonNull;

use crate::ffi;
use crate::ffi::pdf_document_get_metadata;
use crate::ffi::pdf_document_get_version;
use crate::font::Font;
use crate::metadata::Metadata;
use crate::page::PageSize;
use crate::version::Version;

pub struct Document {
    ptr: NonNull<ffi::pdf_document>,
    fonts: Vec<Font>,
    version: Version,
    metadata: Option<Metadata>,
    page_size: Option<PageSize>,
}

impl Document {
    pub fn open(data: &[u8]) -> Option<Document> {
        if data.is_empty() {
            return None;
        }
        let doc = unsafe { ffi::pdf_document_open(data.as_ptr(), data.len()) };
        if doc.is_null() {
            eprintln!("Cannot open document");
            return None;
        }

        let font_count = unsafe { ffi::pdf_document_get_font_count(doc) };
        let mut fonts: Vec<Font> = Vec::with_capacity(font_count);
        for i in 0..font_count {
            let font_ptr = unsafe { ffi::pdf_document_get_font(doc, i) };
            if let Some(font) = unsafe { Font::from_ptr(font_ptr) } {
                fonts.push(font);
            } else {
                eprintln!("Found invalid (null) font at position {i}");
            }
        }

        Some(Document {
            ptr: unsafe { NonNull::new_unchecked(doc) },
            fonts,
            version: Version::from(unsafe { pdf_document_get_version(doc) }),
            metadata: unsafe { Metadata::from_ptr(pdf_document_get_metadata(doc)) },
            page_size: unsafe {
                ffi::pdf_document_get_page_size(doc)
                    .as_ref()
                    .map(PageSize::from)
            },
        })
    }

    pub fn page_count(&self) -> usize {
        unsafe { ffi::pdf_document_get_page_count(self.ptr.as_ptr()) }
    }

    pub fn fonts(&self) -> &[Font] {
        &self.fonts
    }

    pub fn version(&self) -> &Version {
        &self.version
    }

    pub fn metadata(&self) -> Option<&Metadata> {
        self.metadata.as_ref()
    }

    pub fn page_size(&self) -> Option<&PageSize> {
        self.page_size.as_ref()
    }
}

impl Drop for Document {
    fn drop(&mut self) {
        unsafe { ffi::pdf_document_free(self.ptr.as_ptr()) };
    }
}

impl Debug for Document {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_fmt(format_args!(
            "Document({}, version={}, #fonts={})",
            self.ptr.addr(),
            self.version,
            self.fonts.len()
        ))
    }
}
