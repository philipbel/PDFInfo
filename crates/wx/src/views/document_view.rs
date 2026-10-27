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

use wxdragon::prelude::*;

use crate::models::DocumentModel;
use crate::views::{
    View,
    random_color,
};

pub(crate) struct DocumentView {
    document: Rc<DocumentModel>,
    splitter: SplitterWindow,
}

impl DocumentView {
    pub fn new<P: WxWidget>(document: Rc<DocumentModel>, parent: &P) -> Self {
        let splitter = SplitterWindow::builder(parent)
            .with_style(SplitterWindowStyle::LiveUpdate | SplitterWindowStyle::Default)
            .build();
        let main_panel = Panel::builder(&splitter).build();
        main_panel.set_background_color(random_color());
        let sidebar_panel = Panel::builder(&splitter)
            .with_style(PanelStyle::BorderTheme)
            .build();
        splitter.set_minimum_pane_size(100);
        splitter.split_vertically(&main_panel, &sidebar_panel, -250);

        Self { document, splitter }
    }
}

impl View for DocumentView {
    type Root = SplitterWindow;

    fn root_view(&self) -> Self::Root {
        self.splitter
    }
}
