// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::ffi::OsStr;
use std::path::{
    Path,
    PathBuf,
};
use std::rc::Rc;

use pdf_engine::Document;

use crate::models::FontModel;


#[derive(Debug, Clone, Eq, PartialEq)]
pub(crate) struct DocumentModel {
    pub title: String,
    pub file: PathBuf,
    pub fonts: Rc<Vec<FontModel>>,
}


impl DocumentModel {
    pub fn new(file: impl AsRef<Path>, document: Document) -> Self {
        Self {
            title: file
                .as_ref()
                .file_name()
                .map(OsStr::to_string_lossy)
                .as_deref()
                .unwrap_or_default() // TODO: Error handling
                .to_string(),
            file: file.as_ref().to_path_buf(),
            fonts: Rc::new(document.fonts().iter().map(FontModel::from).collect()),
        }
    }
}
