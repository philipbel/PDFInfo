// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::ffi::CString;
use std::path::Path;

mod ffi;

#[derive(Debug, Clone, Copy)]
pub struct FontInfo {
    pub postscript_name: &'static str,
    pub path: &'static Path,
}


impl FontInfo {
    pub fn find(name: &str) -> Option<FontInfo> {
        unsafe { ffi::font_locator_init() };
        let c_name = CString::new(name).ok()?;
        let font = unsafe { ffi::font_locator_find_font(c_name.as_ptr()) };
        if font.is_null() {
            return None;
        }
        let c_postscript_name = unsafe { ffi::font_locator_font_get_postscript_name(font) };
        let postscript_name = (unsafe { common::c_char_ptr_to_str(c_postscript_name) })?;
        let c_path = unsafe { ffi::font_locator_font_get_path(font) };
        let path_str = (unsafe { common::c_char_ptr_to_str(c_path) })?;
        let path = Path::new(path_str);

        Some(FontInfo {
            postscript_name,
            path,
        })
    }
}
