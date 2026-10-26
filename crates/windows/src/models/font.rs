// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use pdf_engine::Font;


#[derive(Debug, Clone, Eq, PartialEq)]
pub(crate) struct FontModel {
    pub id: u64,
    pub display_name: String,
}


impl From<&Font> for FontModel {
    fn from(font: &Font) -> Self {
        Self {
            id: font.id(),
            display_name: font
                .display_name()
                .map(str::to_string)
                .unwrap_or_else(|| "N/A".to_string()), // TODO: Translate
        }
    }
}
