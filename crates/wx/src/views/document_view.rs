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
use crate::views::font_list_view::FontListView;
use crate::views::{
    View,
    random_color,
};

pub(crate) struct DocumentView {
    document: Rc<DocumentModel>,
    splitter: SplitterWindow,
    font_list_view: FontListView,
}


impl DocumentView {
    pub fn new<P: WxWidget>(document: Rc<DocumentModel>, parent: &P) -> Self {
        let splitter = SplitterWindow::builder(parent)
            .with_style(SplitterWindowStyle::LiveUpdate | SplitterWindowStyle::Default)
            .build();
        let font_list_view = FontListView::new(document.clone(), &splitter);
        let sidebar_panel = Panel::builder(&splitter)
            .with_style(PanelStyle::BorderTheme)
            .build();
        splitter.set_minimum_pane_size(100); // TODO: Adjust
        splitter.split_vertically(&font_list_view.root_view(), &sidebar_panel, -250);

        Self {
            document,
            splitter,
            font_list_view,
        }
    }
}


impl View for DocumentView {
    type Root = SplitterWindow;

    fn root_view(&self) -> Self::Root {
        self.splitter
    }
}
