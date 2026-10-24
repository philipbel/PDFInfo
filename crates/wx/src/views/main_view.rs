// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::cell::RefCell;
use std::path::Path;
use std::rc::Rc;

use wxdragon::prelude::*;

use crate::views::{
    DocumentView,
    NoContentView,
    View,
};


pub(crate) struct MainView {
    container: Panel,
    notebook: Notebook,
    document_views: RefCell<Vec<Rc<DocumentView>>>,
    no_content_view: NoContentView,
}

impl MainView {
    pub(crate) fn new<P: wxdragon::prelude::WxWidget>(parent: &P) -> Self {
        let container = Panel::builder(parent).build();
        let container_sizer = BoxSizer::builder(Orientation::Vertical).build();
        container.set_sizer(container_sizer, true);


        let no_content_view = NoContentView::new(
            "No file loaded",
            "Open a file or drag files here.",
            &container,
        );

        let notebook = Notebook::builder(&container)
            .with_style(NotebookStyle::Top | NotebookStyle::Default)
            .build();
        container_sizer.add(&notebook, 1, SizerFlag::Expand, 0);
        container_sizer.add(&no_content_view.root_view(), 1, SizerFlag::Expand, 0);

        notebook.show(false);

        Self {
            container,
            notebook,
            document_views: RefCell::new(Vec::default()),
            no_content_view,
        }
    }

    pub(crate) fn open_document(&self, path: impl AsRef<Path>) {
        match DocumentView::new(&path, &self.notebook) {
            Ok(document_view) => {
                let title = &path
                    .as_ref()
                    .file_name()
                    .unwrap_or_default()
                    .to_string_lossy();
                self.notebook
                    .add_page(&document_view.root_view(), title, true, None);
                self.document_views
                    .borrow_mut()
                    .push(Rc::new(document_view));

                self.no_content_view.root_view().show(false);
                self.notebook.show(true);
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
