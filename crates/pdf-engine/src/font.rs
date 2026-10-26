// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::fmt::{
    Debug,
    Display,
};

use common::c_char_ptr_to_str;

use crate::descriptor::Descriptor;
use crate::ffi;

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
pub enum FontSubtype {
    Type0 = ffi::PDF_FONT_SUBTYPE_TYPE0 as isize,
    Type1 = ffi::PDF_FONT_SUBTYPE_TYPE1 as isize,
    MMType1 = ffi::PDF_FONT_SUBTYPE_MM_TYPE1 as isize,
    Type3 = ffi::PDF_FONT_SUBTYPE_TYPE3 as isize,
    TrueType = ffi::PDF_FONT_SUBTYPE_TRUETYPE as isize,
    CidFontType0 = ffi::PDF_FONT_SUBTYPE_CID_FONT_TYPE0 as isize,
    CidFontType2 = ffi::PDF_FONT_SUBTYPE_CID_FONT_TYPE2 as isize,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
pub enum FontDisplayType {
    Type0 = ffi::PDF_FONT_DISPLAY_TYPE_TYPE0 as isize,
    Type1 = ffi::PDF_FONT_DISPLAY_TYPE_TYPE1 as isize,
    Type1c = ffi::PDF_FONT_DISPLAY_TYPE_TYPE1C as isize,
    Type1cOpenType = ffi::PDF_FONT_DISPLAY_TYPE_TYPE1C_OPEN_TYPE as isize,
    Type3 = ffi::PDF_FONT_DISPLAY_TYPE_TYPE3 as isize,
    TrueType = ffi::PDF_FONT_DISPLAY_TYPE_TRUE_TYPE as isize,
    TrueTypeOpenType = ffi::PDF_FONT_DISPLAY_TYPE_TRUE_TYPE_OPEN_TYPE as isize,
    CidType0 = ffi::PDF_FONT_DISPLAY_TYPE_CID_TYPE0 as isize,
    CidType0c = ffi::PDF_FONT_DISPLAY_TYPE_CID_TYPE0C as isize,
    CidType0cOpenType = ffi::PDF_FONT_DISPLAY_TYPE_CID_TYPE0C_OPEN_TYPE as isize,
    CidTrueType = ffi::PDF_FONT_DISPLAY_TYPE_CID_TRUE_TYPE as isize,
    CidTrueTypeOpenType = ffi::PDF_FONT_DISPLAY_TYPE_CID_TRUE_TYPE_OPEN_TYPE as isize,
}

impl Display for FontSubtype {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            FontSubtype::Type0 => f.write_str("Type0"),
            FontSubtype::Type1 => f.write_str("Type1"),
            FontSubtype::MMType1 => f.write_str("MMType1"),
            FontSubtype::Type3 => f.write_str("Type3"),
            FontSubtype::TrueType => f.write_str("TrueType"),
            FontSubtype::CidFontType0 => f.write_str("CIDFontType0"),
            FontSubtype::CidFontType2 => f.write_str("CIDFontType2"),
        }
    }
}

pub type FontId = u64;

pub struct Font {
    ptr: *const ffi::pdf_font,
}

impl Font {
    pub(crate) unsafe fn from_ptr(f: *const ffi::pdf_font) -> Option<Font> {
        if f.is_null() {
            return None;
        }
        Some(Font { ptr: f })
    }

    pub fn id(&self) -> FontId {
        unsafe { ffi::pdf_font_get_id(self.ptr) }
    }

    pub fn display_name(&self) -> Option<&str> {
        unsafe { c_char_ptr_to_str(ffi::pdf_font_get_display_name(self.ptr)) }
    }

    pub fn subtype(&self) -> FontSubtype {
        let subtype = unsafe { ffi::pdf_font_get_subtype(self.ptr) };
        match subtype {
            ffi::PDF_FONT_SUBTYPE_TYPE0 => FontSubtype::Type0,
            ffi::PDF_FONT_SUBTYPE_TYPE1 => FontSubtype::Type1,
            ffi::PDF_FONT_SUBTYPE_MM_TYPE1 => FontSubtype::MMType1,
            ffi::PDF_FONT_SUBTYPE_TYPE3 => FontSubtype::Type3,
            ffi::PDF_FONT_SUBTYPE_TRUETYPE => FontSubtype::TrueType,
            ffi::PDF_FONT_SUBTYPE_CID_FONT_TYPE0 => FontSubtype::CidFontType0,
            ffi::PDF_FONT_SUBTYPE_CID_FONT_TYPE2 => FontSubtype::CidFontType2,
            _ => unreachable!("Unrecognized subtype {}", subtype),
        }
    }

    pub fn base_font(&self) -> Option<&str> {
        unsafe { c_char_ptr_to_str(ffi::pdf_font_get_base_font(self.ptr)) }
    }

    pub fn cmap_name(&self) -> Option<&str> {
        unsafe { c_char_ptr_to_str(ffi::pdf_font_get_cmap_name(self.ptr)) }
    }

    pub fn is_subset(&self) -> bool {
        unsafe { ffi::pdf_font_is_subset(self.ptr) }
    }

    pub fn is_embedded(&self) -> bool {
        unsafe { ffi::pdf_font_is_embedded(self.ptr) }
    }

    pub fn descriptor(&self) -> Option<Descriptor<'_>> {
        unsafe { Descriptor::from_ptr(ffi::pdf_font_get_descriptor(self.ptr)) }
    }

    pub fn display_type(&self) -> FontDisplayType {
        let dt = unsafe { ffi::pdf_font_get_display_type(self.ptr) };
        match dt {
            ffi::PDF_FONT_DISPLAY_TYPE_TYPE0 => FontDisplayType::Type0,
            ffi::PDF_FONT_DISPLAY_TYPE_TYPE1 => FontDisplayType::Type1,
            ffi::PDF_FONT_DISPLAY_TYPE_TYPE1C => FontDisplayType::Type1c,
            ffi::PDF_FONT_DISPLAY_TYPE_TYPE1C_OPEN_TYPE => FontDisplayType::Type1cOpenType,
            ffi::PDF_FONT_DISPLAY_TYPE_TYPE3 => FontDisplayType::Type3,
            ffi::PDF_FONT_DISPLAY_TYPE_TRUE_TYPE => FontDisplayType::TrueType,
            ffi::PDF_FONT_DISPLAY_TYPE_TRUE_TYPE_OPEN_TYPE => FontDisplayType::TrueTypeOpenType,
            ffi::PDF_FONT_DISPLAY_TYPE_CID_TYPE0 => FontDisplayType::CidType0,
            ffi::PDF_FONT_DISPLAY_TYPE_CID_TYPE0C => FontDisplayType::CidType0c,
            ffi::PDF_FONT_DISPLAY_TYPE_CID_TYPE0C_OPEN_TYPE => FontDisplayType::CidType0cOpenType,
            ffi::PDF_FONT_DISPLAY_TYPE_CID_TRUE_TYPE => FontDisplayType::CidTrueType,
            ffi::PDF_FONT_DISPLAY_TYPE_CID_TRUE_TYPE_OPEN_TYPE => {
                FontDisplayType::CidTrueTypeOpenType
            }
            _ => unreachable!("Unrecognized display type {}", dt),
        }
    }
}

impl Debug for Font {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Font")
            .field("ptr", &self.ptr)
            .field("id", &self.id())
            .field("display_name", &self.display_name())
            .field("base_font", &self.base_font())
            .field("subtype", &self.subtype())
            .field("is_subset", &self.is_subset())
            .field("is_embedded", &self.is_embedded())
            .field("cmap_name", &self.cmap_name())
            .finish()
    }
}

impl PartialEq for Font {
    fn eq(&self, other: &Self) -> bool {
        self.ptr == other.ptr
    }
}
