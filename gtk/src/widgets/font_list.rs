// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use adw::prelude::*;
use adw::subclass::prelude::*;
use gettextrs::gettext;
use gtk::glib;
use log::{
    debug,
    warn,
};

use crate::model::{
    PdfDocument,
    PdfFont,
};

mod imp {
    use std::cell::RefCell;

    use font_locator::FontInfo;
    use gtk::glib::Properties;
    use pdf_engine::FontDisplayType;

    use super::*;

    #[derive(Default, Properties)]
    #[properties(wrapper_type = super::FontList)]
    pub struct FontList {
        #[property(get, set, nullable)]
        document: RefCell<Option<PdfDocument>>,

        #[property(get, set, nullable)]
        pub(super) selected_font: RefCell<Option<PdfFont>>,

        pub(super) column_view: gtk::ColumnView,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for FontList {
        type ParentType = adw::Bin;
        type Type = super::FontList;

        const NAME: &'static str = "PdfInfoFontList";
    }

    #[glib::derived_properties]
    impl ObjectImpl for FontList {
        fn constructed(&self) {
            self.parent_constructed();
            let obj = self.obj();

            // Model
            {
                let sort_model = gtk::SortListModel::default();
                sort_model.set_sorter(self.column_view.sorter().as_ref());
                let selection_model = gtk::SingleSelection::new(Some(sort_model));
                self.column_view.set_model(Some(&selection_model));

                // When items are added, they may be selected, and selection-changed is not emitted. So,
                // we need to listen for both selection-changed and items-changed.
                //
                // See https://docs.gtk.org/gtk4/iface.SelectionModel.html#description
                selection_model.connect_selection_changed(glib::clone!(
                    #[weak(rename_to = font_list)]
                    obj,
                    move |model, _, _| {
                        font_list.selection_maybe_changed(model.selected_item());
                    }
                ));
                selection_model.connect_items_changed(glib::clone!(
                    #[weak(rename_to = font_list)]
                    obj,
                    move |model, _, _, _| {
                        font_list.selection_maybe_changed(model.selected_item());
                    }
                ));
            }

            // Column view
            {
                self.column_view.set_show_column_separators(false);
                self.column_view.set_show_row_separators(false);
                self.column_view.set_reorderable(false);

                let name_column = &Self::make_text_column(&gettext("Name"), true, |f| {
                    f.font().display_name().unwrap_or_default().to_string()
                });
                self.column_view.append_column(name_column);
                self.column_view
                    .sort_by_column(Some(name_column), gtk::SortType::Ascending);

                self.column_view.append_column(&Self::make_text_column(
                    &gettext("Type"),
                    true,
                    |f| Self::display_type_to_string(f.font().display_type()),
                ));
                self.column_view
                    .append_column(&Self::make_check_column(&gettext("Subset"), |f| {
                        f.font().is_subset()
                    }));
                self.column_view
                    .append_column(&Self::make_check_column(&gettext("Embedded"), |f| {
                        f.font().is_embedded()
                    }));
                self.column_view.append_column(&Self::make_check_column(
                    &gettext("Installed"),
                    |f| {
                        f.font()
                            .display_name()
                            .map(|n| FontInfo::find(n).is_some())
                            .unwrap_or(false)
                    },
                ));

                let scrolled_window = gtk::ScrolledWindow::builder()
                    .hscrollbar_policy(gtk::PolicyType::Never)
                    .vexpand(true)
                    .build();
                scrolled_window.set_child(Some(&self.column_view));
                obj.set_child(Some(&scrolled_window));
            }

            obj.connect_document_notify(|i| {
                i.document_updated();
            });
        }
    }

    impl WidgetImpl for FontList {
    }

    impl BinImpl for FontList {
    }

    impl FontList {
        fn make_text_column(
            title: &str,
            expand: bool,
            text_fn: fn(&PdfFont) -> String,
        ) -> gtk::ColumnViewColumn {
            let factory = gtk::SignalListItemFactory::new();
            factory.connect_setup(|_, item| {
                let item = item.downcast_ref::<gtk::ListItem>().expect("ListItem");
                item.set_child(Some(&gtk::Label::builder().xalign(0.0).build()));
            });
            factory.connect_bind(move |_, item| {
                let item = item.downcast_ref::<gtk::ListItem>().expect("ListItem");
                let font = item.item().and_downcast::<PdfFont>().expect("PdfFont");
                let label = item
                    .child()
                    .and_downcast::<gtk::Label>()
                    .expect("gtk::Label");
                label.set_label(&text_fn(&font));
            });

            let sorter = gtk::CustomSorter::new(move |a, b| {
                let a = a.downcast_ref::<PdfFont>().expect("PdfFont");
                let b = b.downcast_ref::<PdfFont>().expect("PdfFont");
                let a_text = text_fn(a);
                let b_text = text_fn(b);
                let a_key = glib::CollationKey::from(a_text);
                let b_key = glib::CollationKey::from(b_text);
                a_key.cmp(&b_key).into()
            });

            gtk::ColumnViewColumn::builder()
                .title(title)
                .expand(expand)
                .resizable(true)
                .factory(&factory)
                .sorter(&sorter)
                .build()
        }

        fn make_check_column(title: &str, value_fn: fn(&PdfFont) -> bool) -> gtk::ColumnViewColumn {
            let factory = gtk::SignalListItemFactory::new();
            factory.connect_setup(|_, item| {
                let item = item.downcast_ref::<gtk::ListItem>().expect("ListItem");
                item.set_child(Some(&gtk::Image::from_icon_name("object-select-symbolic")));
            });
            factory.connect_bind(move |_, item| {
                let item = item.downcast_ref::<gtk::ListItem>().expect("ListItem");
                let font = item.item().and_downcast::<PdfFont>().expect("PdfFont");
                let image = item.child().and_downcast::<gtk::Image>().expect("Image");
                image.set_visible(value_fn(&font))
            });
            let sorter = gtk::CustomSorter::new(move |a, b| {
                let a = a.downcast_ref::<PdfFont>().expect("PdfFont");
                let b = b.downcast_ref::<PdfFont>().expect("PdfFont");
                value_fn(a).cmp(&value_fn(b)).into()
            });
            gtk::ColumnViewColumn::builder()
                .title(title)
                .factory(&factory)
                .sorter(&sorter)
                .build()
        }

        fn display_type_to_string(display_type: FontDisplayType) -> String {
            match display_type {
                FontDisplayType::Type0 => gettext("Type 0"),
                FontDisplayType::Type1 => gettext("Type 1"),
                FontDisplayType::Type1c => gettext("Type 1C"),
                FontDisplayType::Type1cOpenType => gettext("Type 1C (OpenType)"),
                FontDisplayType::Type3 => gettext("Type 3"),
                FontDisplayType::TrueType => gettext("TrueType"),
                FontDisplayType::TrueTypeOpenType => gettext("TrueType (OpenType)"),
                FontDisplayType::CidType0 => gettext("CID Type 0"),
                FontDisplayType::CidType0c => gettext("CID Type 0C"),
                FontDisplayType::CidType0cOpenType => gettext("CID Type0C (OpenType)"),
                FontDisplayType::CidTrueType => gettext("CID TrueType"),
                FontDisplayType::CidTrueTypeOpenType => gettext("CID TrueType (OpenType)"),
            }
        }
    }
}

glib::wrapper! {
    pub struct FontList(ObjectSubclass<imp::FontList>)
        @extends adw::Bin, gtk::Widget,
        @implements gtk::Buildable, gtk::ConstraintTarget, gtk::Accessible;
}

impl FontList {
    pub fn new() -> Self {
        glib::Object::builder().build()
    }

    fn document_updated(&self) {
        let imp = self.imp();
        let list_model = imp
            .column_view
            .model()
            .as_ref()
            .and_then(Cast::downcast_ref::<gtk::SingleSelection>)
            .and_then(|m| m.model());
        let sort_model = list_model
            .as_ref()
            .and_then(Cast::downcast_ref::<gtk::SortListModel>);
        if let Some(m) = sort_model {
            m.set_model(self.document().as_ref());
        } else {
            warn!("No selection model in list view");
        };
        imp.selected_font.replace(None);
    }

    fn selection_maybe_changed(&self, selected_item: Option<glib::Object>) {
        let selected_font = selected_item.and_downcast_ref::<PdfFont>();
        debug!(
            "selection_maybe_changed: selection={:?}",
            selected_font.and_then(|f| f.font().display_name())
        );
        self.set_selected_font(selected_font);
    }
}

impl Default for FontList {
    fn default() -> Self {
        Self::new()
    }
}
