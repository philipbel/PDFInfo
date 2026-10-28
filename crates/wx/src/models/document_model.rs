// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::path::{
    Path,
    PathBuf,
};
use std::rc::Rc;
use std::{
    fs,
    io,
};

use log::{
    debug,
    warn,
};
use thiserror::Error;

use crate::models::FontModel;
use crate::models::font_list_model::FontListModel;


#[derive(Error, Debug)]
pub(crate) enum DocumentError {
    #[error("IO error: {0}")]
    Io(#[from] io::Error),
    #[error("Failed to load '{0}'")]
    Load(PathBuf),
}


pub(crate) struct DocumentModel {
    pub(crate) path: PathBuf,
    pub(crate) title: String,
    pub(crate) fonts: Vec<Rc<FontModel>>,
}


impl DocumentModel {
    pub(crate) fn new(path: impl AsRef<Path>) -> Result<Self, DocumentError> {
        let content = fs::read(&path)?;
        let document = pdf_engine::Document::open(&content)
            .ok_or_else(|| DocumentError::Load(path.as_ref().to_path_buf()))
            .inspect_err(|e| warn!("failed to load {}: {e}", path.as_ref().display()))?;

        let fonts: Vec<Rc<FontModel>> = document
            .fonts()
            .iter()
            .map(FontModel::from)
            .map(Rc::new)
            .collect();

        debug!(
            "{}: loaded {} font(s)",
            path.as_ref().display(),
            fonts.len()
        );

        let title = &path
            .as_ref()
            .file_name()
            .unwrap_or_default()
            .to_string_lossy();

        Ok(Self {
            path: path.as_ref().into(),
            title: title.to_string(),
            fonts,
        })
    }
}


impl FontListModel for DocumentModel {
    fn fonts(&self) -> &[Rc<FontModel>] {
        &self.fonts
    }
}
