// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use gtk::gio::prelude::*;
use gtk::glib::subclass::prelude::*;
use gtk::{
    gio,
    glib,
};
use thiserror::Error;

mod imp {
    use std::cell::OnceCell;

    use glib::Properties;
    use gtk::gio::subclass::prelude::ListModelImpl;

    use super::*;
    use crate::model::PdfFont;

    #[derive(Default, Debug, Properties)]
    #[properties(wrapper_type = super::PdfDocument)]
    pub struct PdfDocument {
        pub(super) document: OnceCell<pdf_engine::Document>,
        #[property(get, set, nullable)]
        pub(super) file: OnceCell<gio::File>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for PdfDocument {
        type Interfaces = (gio::ListModel,);
        type ParentType = gtk::glib::Object;
        type Type = super::PdfDocument;

        const NAME: &'static str = "PdfInfoDocument";
    }

    #[glib::derived_properties]
    impl ObjectImpl for PdfDocument {
    }
    impl ListModelImpl for PdfDocument {
        fn item_type(&self) -> glib::Type {
            PdfFont::static_type()
        }

        fn n_items(&self) -> u32 {
            self.document
                .get()
                .map(|d| d.fonts().len() as u32)
                .unwrap_or_default()
        }

        fn item(&self, position: u32) -> Option<glib::Object> {
            PdfFont::new(self.obj().clone(), position as usize).map(Cast::upcast)
        }
    }
}

glib::wrapper! {
    pub struct PdfDocument(ObjectSubclass<imp::PdfDocument>)
        @implements gio::ListModel;
}

#[derive(Error, Debug)]
pub enum PdfDocumentError {
    #[error("could not read file: {0}")]
    Read(#[from] glib::Error),
    #[error("file is not a valid PDF document")]
    Invalid,
}

impl PdfDocument {
    pub async fn from_file(file: gio::File) -> Result<Self, PdfDocumentError> {
        let (bytes, _) = file.load_contents_future().await?;
        let document = pdf_engine::Document::open(&bytes).ok_or(PdfDocumentError::Invalid)?;

        let obj: Self = glib::Object::builder()
            .property("file", file.clone())
            .build();
        let imp = obj.imp();
        _ = imp.document.set(document);
        Ok(obj)
    }

    pub fn document(&self) -> &pdf_engine::Document {
        self.imp().document.get().expect("set in from_file()")
    }
}
