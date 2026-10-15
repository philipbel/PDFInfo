// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::fmt::Display;

use crate::ffi;

pub struct Version {
    major: u32,
    minor: u32,
    extension: u32,
}

impl Version {
    pub(crate) fn from(v: ffi::pdf_document_version) -> Version {
        Version {
            major: v.major,
            minor: v.minor,
            extension: v.extension,
        }
    }
}

impl Display for Version {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_fmt(format_args!("{}.{}", self.major, self.minor))?;
        if self.extension > 0 {
            f.write_fmt(format_args!(".{}", self.extension))?;
        }
        Ok(())
    }
}
