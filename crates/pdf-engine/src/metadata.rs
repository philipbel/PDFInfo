// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::fmt::Debug;

use common::c_char_ptr_to_str;

use crate::ffi;

pub struct Metadata {
    ptr: *const ffi::pdf_document_metadata,
}

impl Metadata {
    pub(crate) unsafe fn from_ptr(m: *const ffi::pdf_document_metadata) -> Option<Metadata> {
        if m.is_null() {
            return None;
        }

        Some(Metadata { ptr: m })
    }

    pub fn title(&self) -> Option<&str> {
        unsafe { c_char_ptr_to_str(ffi::pdf_document_metadata_get_title(self.ptr)) }
    }

    pub fn author(&self) -> Option<&str> {
        unsafe { c_char_ptr_to_str(ffi::pdf_document_metadata_get_author(self.ptr)) }
    }

    pub fn subject(&self) -> Option<&str> {
        unsafe { c_char_ptr_to_str(ffi::pdf_document_metadata_get_subject(self.ptr)) }
    }

    pub fn keywords(&self) -> Vec<&str> {
        let keyword_count = unsafe { ffi::pdf_document_metadata_get_keyword_count(self.ptr) };
        let mut keywords = Vec::with_capacity(keyword_count);
        for i in 0..keyword_count {
            let keyword =
                unsafe { c_char_ptr_to_str(ffi::pdf_document_metadata_get_keyword(self.ptr, i)) };
            if let Some(k) = keyword {
                keywords.push(k);
            }
        }
        keywords
    }

    pub fn creator(&self) -> Option<&str> {
        unsafe { c_char_ptr_to_str(ffi::pdf_document_metadata_get_creator(self.ptr)) }
    }

    pub fn producer(&self) -> Option<&str> {
        unsafe { c_char_ptr_to_str(ffi::pdf_document_metadata_get_producer(self.ptr)) }
    }

    pub fn creation_date(&self) -> Option<i64> {
        unsafe {
            ffi::pdf_document_metadata_get_creation_date(self.ptr)
                .as_ref()
                .copied()
        }
    }

    pub fn mod_date(&self) -> Option<i64> {
        unsafe {
            ffi::pdf_document_metadata_get_mod_date(self.ptr)
                .as_ref()
                .copied()
        }
    }

    pub fn trapped(&self) -> Option<bool> {
        unsafe {
            ffi::pdf_document_metadata_get_trapped(self.ptr)
                .as_ref()
                .copied()
        }
    }
}

impl Debug for Metadata {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Metadata")
            .field("ptr", &self.ptr)
            .field("title", &self.title())
            .field("author", &self.author())
            .field("subject", &self.subject())
            .field("keywords", &self.keywords())
            .field("creator", &self.creator())
            .field("producer", &self.producer())
            .field("creation_date", &self.creation_date())
            .field("mod_date", &self.mod_date())
            .field("trapped", &self.trapped())
            .finish()
    }
}
