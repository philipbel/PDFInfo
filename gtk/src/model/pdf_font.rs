// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use gtk::glib::subclass::prelude::*;
use gtk::glib::{
    self,
};
use log::warn;

use crate::model::PdfDocument;


mod imp {
    use std::cell::OnceCell;

    use super::*;

    #[derive(Default, Debug)]
    pub struct PdfFont {
        pub(super) document: OnceCell<PdfDocument>,
        pub(super) index: OnceCell<usize>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for PdfFont {
        type ParentType = gtk::glib::Object;
        type Type = super::PdfFont;

        const NAME: &'static str = "PdfInfoFont";
    }

    impl ObjectImpl for PdfFont {
    }
}

glib::wrapper! {
    pub struct PdfFont(ObjectSubclass<imp::PdfFont>);
}

impl PdfFont {
    pub fn new(document: PdfDocument, index: usize) -> Option<Self> {
        if Self::is_valid_index(&document, index) {
            let obj: Self = glib::Object::builder().build();
            let imp = obj.imp();
            _ = imp.document.set(document);
            _ = imp.index.set(index);
            Some(obj)
        } else {
            None
        }
    }

    pub fn font(&self) -> &pdf_engine::Font {
        let imp = self.imp();
        let document = imp.document.get().expect("set in new()");
        let index = imp.index.get().expect("set in new()");
        let fonts = document.document().fonts();
        &fonts[*index]
    }

    fn is_valid_index(document: &PdfDocument, index: usize) -> bool {
        if index >= document.document().fonts().len() {
            warn!("Invalid font index {index}");
            return false;
        }
        true
    }
}
