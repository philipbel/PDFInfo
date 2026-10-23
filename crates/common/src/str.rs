// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::ffi::CStr;

pub unsafe fn c_char_ptr_to_str<'a>(c_char_ptr: *const std::ffi::c_char) -> Option<&'a str> {
    if c_char_ptr.is_null() {
        return None;
    }
    let c_str = unsafe { CStr::from_ptr(c_char_ptr) };
    match c_str.to_str() {
        Err(e) => {
            // TODO: report error
            eprintln!("Error converting string: {e}");
            None
        }
        Ok(s) => Some(s),
    }
}
