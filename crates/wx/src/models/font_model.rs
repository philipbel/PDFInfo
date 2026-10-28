// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use pdf_engine::{
    Font,
    FontDisplayType,
};


pub(crate) struct FontModel {
    pub display_name: String,
    pub display_type: String,
    pub is_embedded: bool,
    pub is_installed: bool,
}


impl FontModel {
    fn display_type_string(display_type: FontDisplayType) -> String {
        // TODO: Translate
        match display_type {
            FontDisplayType::Type0 => "Type 0",
            FontDisplayType::Type1 => "Type 1",
            FontDisplayType::Type1c => "Type 1C",
            FontDisplayType::Type1cOpenType => "Type1C (OpenType)",
            FontDisplayType::Type3 => "Type 3",
            FontDisplayType::TrueType => "TrueType",
            FontDisplayType::TrueTypeOpenType => "TrueType (OpenType)",
            FontDisplayType::CidType0 => "CID Type 0",
            FontDisplayType::CidType0c => "CID Type 0C",
            FontDisplayType::CidType0cOpenType => "CID Type 0C (OpenType)",
            FontDisplayType::CidTrueType => "CID TrueType",
            FontDisplayType::CidTrueTypeOpenType => "CID TrueType (OpenType)",
        }
        .to_string()
    }
}

impl From<&Font> for FontModel {
    fn from(font: &Font) -> Self {
        Self {
            // TODO: Translate
            display_name: font.display_name().unwrap_or("N/A").to_string(),
            display_type: Self::display_type_string(font.display_type()),
            is_embedded: font.is_embedded(),
            is_installed: false, // TODO: Implement
        }
    }
}
