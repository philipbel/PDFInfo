// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::cell::RefCell;
use std::path::Path;
use std::rc::Rc;

use wxdragon::prelude::*;

use crate::Icon;
use crate::models::DocumentModel;
use crate::views::{
    DocumentView,
    PlaceholderView,
    View,
};


// XXX: wxDragon doesn't have these...
const WX_AUI_NB_TOP: u32 = 1 << 0;
const WX_AUI_NB_LEFT: u32 = 1 << 1; // not implemented yet
const WX_AUI_NB_RIGHT: u32 = 1 << 2; // not implemented yet
const WX_AUI_NB_BOTTOM: u32 = 1 << 3;
const WX_AUI_NB_TAB_SPLIT: u32 = 1 << 4;
const WX_AUI_NB_TAB_MOVE: u32 = 1 << 5;
const WX_AUI_NB_TAB_EXTERNAL_MOVE: u32 = 1 << 6;
const WX_AUI_NB_TAB_FIXED_WIDTH: u32 = 1 << 7;
const WX_AUI_NB_SCROLL_BUTTONS: u32 = 1 << 8;
const WX_AUI_NB_WINDOWLIST_BUTTON: u32 = 1 << 9;
const WX_AUI_NB_CLOSE_BUTTON: u32 = 1 << 10;
const WX_AUI_NB_CLOSE_ON_ACTIVE_TAB: u32 = 1 << 11;
const WX_AUI_NB_CLOSE_ON_ALL_TABS: u32 = 1 << 12;
const WX_AUI_NB_MIDDLE_CLICK_CLOSE: u32 = 1 << 13;
const WX_AUI_NB_MULTILINE: u32 = 1 << 14;
const WX_AUI_NB_PIN_ON_ACTIVE_TAB: u32 = 1 << 15;
const WX_AUI_NB_UNPIN_ON_ALL_PINNED: u32 = 1 << 16;
const WX_AUI_NB_DEFAULT_STYLE: u32 = WX_AUI_NB_TOP
    | WX_AUI_NB_TAB_SPLIT
    | WX_AUI_NB_TAB_MOVE
    | WX_AUI_NB_SCROLL_BUTTONS
    | WX_AUI_NB_CLOSE_ON_ACTIVE_TAB
    | WX_AUI_NB_MIDDLE_CLICK_CLOSE;


pub(crate) struct MainView {
    container: Panel,
    notebook: AuiNotebook,
    document_views: RefCell<Vec<Rc<DocumentView>>>,
    placeholder_view: PlaceholderView,
}

impl MainView {
    pub(crate) fn new<P: wxdragon::prelude::WxWidget>(parent: &P) -> Self {
        let container = Panel::builder(parent).build();
        let container_sizer = BoxSizer::builder(Orientation::Vertical).build();
        container.set_sizer(container_sizer, true);

        let placeholder_view = PlaceholderView::new(
            "No file loaded",
            "Open a file or drag files here.",
            Icon::DocumentPdfFilled,
            &container,
        );

        let notebook = AuiNotebook::builder(&container)
            .with_style(AuiNotebookStyle::from_bits_retain(
                (WX_AUI_NB_TOP
                    | WX_AUI_NB_CLOSE_ON_ALL_TABS
                    | WX_AUI_NB_TAB_FIXED_WIDTH
                    | WX_AUI_NB_SCROLL_BUTTONS
                    | WX_AUI_NB_MIDDLE_CLICK_CLOSE) as i64,
            ))
            .build();
        container_sizer.add(&notebook, 1, SizerFlag::Expand, 0);
        container_sizer.add(&placeholder_view.root_view(), 1, SizerFlag::Expand, 0);

        notebook.show(false);

        Self {
            container,
            notebook,
            document_views: RefCell::new(Vec::default()),
            placeholder_view,
        }
    }

    pub(crate) fn open_document(&self, path: impl AsRef<Path>) {
        match DocumentModel::new(&path).map(Rc::new) {
            Ok(document) => {
                let document_view = DocumentView::new(document.clone(), &self.notebook);
                // TODO: Error handling
                // TODO: wxDragon doesn't expose `wxAuiNotebook::AddPage` that accepts a
                // BitmapBundle. Add it.
                _ = self
                    .notebook
                    .add_page(&document_view.root_view(), &document.title, true);
                self.document_views
                    .borrow_mut()
                    .push(Rc::new(document_view));

                self.placeholder_view.root_view().show(false);
                self.notebook.show(true);

                self.container.layout();
            }
            Err(err) => {
                // TODO: Show error
                panic!("Error opening {}: {err}", path.as_ref().display());
            }
        }
    }
}

impl View for MainView {
    type Root = Panel;

    fn root_view(&self) -> Self::Root {
        self.container
    }
}
