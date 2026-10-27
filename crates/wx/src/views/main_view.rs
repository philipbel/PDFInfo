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


pub(crate) struct MainView {
    container: Panel,
    notebook: Notebook,
    document_views: RefCell<Vec<Rc<DocumentView>>>,
    no_content_view: PlaceholderView,
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

        let notebook = Notebook::builder(&container)
            .with_style(NotebookStyle::Top | NotebookStyle::Default)
            .build();
        container_sizer.add(&notebook, 1, SizerFlag::Expand, 0);
        container_sizer.add(&placeholder_view.root_view(), 1, SizerFlag::Expand, 0);

        notebook.show(false);

        Self {
            container,
            notebook,
            document_views: RefCell::new(Vec::default()),
            no_content_view: placeholder_view,
        }
    }

    pub(crate) fn open_document(&self, path: impl AsRef<Path>) {
        match DocumentModel::new(&path).map(Rc::new) {
            Ok(document) => {
                let document_view = DocumentView::new(document.clone(), &self.notebook);
                self.notebook
                    .add_page(&document_view.root_view(), &document.title, true, None);
                self.document_views
                    .borrow_mut()
                    .push(Rc::new(document_view));

                self.no_content_view.root_view().show(false);
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
