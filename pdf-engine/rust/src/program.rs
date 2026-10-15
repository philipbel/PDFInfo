// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use crate::{Font, ffi};
use std::fmt::Debug;
use std::{marker::PhantomData, slice};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum ProgramKind {
    Type1 = ffi::PDF_FONT_PROGRAM_KIND_TYPE1 as isize,
    TrueType = ffi::PDF_FONT_PROGRAM_KIND_TRUE_TYPE as isize,
    Type1c = ffi::PDF_FONT_PROGRAM_KIND_TYPE1C as isize,
    CidFontType0c = ffi::PDF_FONT_PROGRAM_KIND_CID_FONT_TYPE0C as isize,
    OpenType = ffi::PDF_FONT_PROGRAM_KIND_OPEN_TYPE as isize,
}

pub struct Program<'a> {
    ptr: *const ffi::pdf_font_program,
    _font: PhantomData<&'a Font>, // tie the program's lifetime to the font
}

impl<'a> Program<'a> {
    pub(crate) unsafe fn from_ptr(ptr: *const ffi::pdf_font_program) -> Option<Program<'a>> {
        if ptr.is_null() {
            None
        } else {
            Some(Program {
                ptr,
                _font: PhantomData,
            })
        }
    }

    pub fn kind(&self) -> ProgramKind {
        let kind = unsafe { ffi::pdf_font_program_get_kind(self.ptr) };
        match kind {
            ffi::PDF_FONT_PROGRAM_KIND_TYPE1 => ProgramKind::Type1,
            ffi::PDF_FONT_PROGRAM_KIND_TRUE_TYPE => ProgramKind::TrueType,
            ffi::PDF_FONT_PROGRAM_KIND_TYPE1C => ProgramKind::Type1c,
            ffi::PDF_FONT_PROGRAM_KIND_CID_FONT_TYPE0C => ProgramKind::CidFontType0c,
            ffi::PDF_FONT_PROGRAM_KIND_OPEN_TYPE => ProgramKind::OpenType,
            _ => unreachable!("Unrecognized program kind {}", kind),
        }
    }

    pub fn data(&self) -> &'a [u8] {
        unsafe {
            let data = ffi::pdf_font_program_get_data(self.ptr);
            if data.is_null() {
                return &[];
            }
            let len = ffi::pdf_font_program_get_size(self.ptr);
            slice::from_raw_parts(data, len)
        }
    }
}

impl<'a> Debug for Program<'a> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Program")
            .field("ptr", &self.ptr)
            .field("kind", &self.kind())
            .field("data", &format_args!("{} byte(s)", self.data().len()))
            .finish()
    }
}
