// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::path::{
    Path,
    PathBuf,
};
use std::{
    fs,
    io,
};

use thiserror::Error;
use wxdragon::prelude::*;

use crate::views::View;


#[derive(Error, Debug)]
pub(crate) enum DocumentError {
    #[error("IO error: {0}")]
    Io(#[from] io::Error),
    #[error("Failed to load '{0}'")]
    Load(PathBuf),
}

pub(crate) struct DocumentView {
    document: pdf_engine::Document,
    splitter: SplitterWindow,
}

impl DocumentView {
    pub fn new<P: WxWidget>(path: impl AsRef<Path>, parent: &P) -> Result<Self, DocumentError> {
        let content = fs::read(&path)?;
        let document = pdf_engine::Document::open(&content)
            .ok_or_else(|| DocumentError::Load(path.as_ref().to_path_buf()))?;

        let splitter = SplitterWindow::builder(parent)
            .with_style(SplitterWindowStyle::LiveUpdate | SplitterWindowStyle::Default)
            .build();
        let main_panel = Panel::builder(&splitter).build();
        let sidebar_panel = Panel::builder(&splitter)
            .with_style(PanelStyle::BorderTheme)
            .build();
        splitter.set_minimum_pane_size(100);
        splitter.split_vertically(&main_panel, &sidebar_panel, -250);

        Ok(Self { document, splitter })
    }
}

impl View for DocumentView {
    type Root = SplitterWindow;

    fn root_view(&self) -> Self::Root {
        self.splitter
    }
}
