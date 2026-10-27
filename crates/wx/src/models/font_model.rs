// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use pdf_engine::Font;


pub(crate) struct FontModel {
    pub display_name: String,
}


impl From<&Font> for FontModel {
    fn from(font: &Font) -> Self {
        Self {
            // TODO: Translate
            display_name: font.display_name().unwrap_or("N/A").to_string(),
        }
    }
}
