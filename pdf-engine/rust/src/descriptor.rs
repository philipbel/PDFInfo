// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::fmt::Debug;
use std::marker::PhantomData;

use bitflags::bitflags;
use common::c_char_ptr_to_str;

use crate::{
    Font,
    Program,
    ffi,
};

bitflags! {
    #[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
    pub struct DescriptorFlags: u32 {
        const FIXED_PITCH = ffi::PDF_FONT_DESCRIPTOR_FLAG_FIXED_PITCH;
        const SERIF = ffi::PDF_FONT_DESCRIPTOR_FLAG_SERIF;
        const SYMBOLIC = ffi::PDF_FONT_DESCRIPTOR_FLAG_SYMBOLIC;
        const SCRIPT = ffi::PDF_FONT_DESCRIPTOR_FLAG_SCRIPT;
        const NON_SYMBOLIC = ffi::PDF_FONT_DESCRIPTOR_FLAG_NON_SYMBOLIC;
        const ITALIC = ffi::PDF_FONT_DESCRIPTOR_FLAG_ITALIC;
        const ALL_CAP = ffi::PDF_FONT_DESCRIPTOR_FLAG_ALL_CAP;
        const SMALL_CAP = ffi::PDF_FONT_DESCRIPTOR_FLAG_SMALL_CAP;
        const FORCE_BOLD = ffi::PDF_FONT_DESCRIPTOR_FLAG_FORCE_BOLD;
    }
}

pub struct Descriptor<'a> {
    ptr: *const ffi::pdf_font_descriptor,
    _font: PhantomData<&'a Font>, // tie the descriptor's lifetime to the font
}

impl<'a> Descriptor<'a> {
    pub(crate) unsafe fn from_ptr(ptr: *const ffi::pdf_font_descriptor) -> Option<Descriptor<'a>> {
        if ptr.is_null() {
            None
        } else {
            Some(Descriptor {
                ptr,
                _font: PhantomData,
            })
        }
    }

    pub fn name(&self) -> Option<&'a str> {
        unsafe { c_char_ptr_to_str(ffi::pdf_font_descriptor_get_name(self.ptr)) }
    }

    pub fn family(&self) -> Option<&'a str> {
        unsafe { c_char_ptr_to_str(ffi::pdf_font_descriptor_get_family(self.ptr)) }
    }

    pub fn weight(&self) -> Option<u32> {
        unsafe {
            ffi::pdf_font_descriptor_get_weight(self.ptr)
                .as_ref()
                .and_then(|x| u32::try_from(*x).ok())
        }
    }

    pub fn flags(&self) -> DescriptorFlags {
        DescriptorFlags::from_bits_truncate(unsafe { ffi::pdf_font_descriptor_get_flags(self.ptr) })
    }

    pub fn program(&self) -> Option<Program<'a>> {
        unsafe { Program::from_ptr(ffi::pdf_font_descriptor_get_program(self.ptr)) }
    }
}

impl<'a> Debug for Descriptor<'a> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Descriptor")
            .field("ptr", &self.ptr)
            .field("name", &self.name())
            .field("family", &self.family())
            .field("weight", &self.weight())
            .field("flags", &self.flags())
            .field("program", &self.program())
            .finish()
    }
}
