// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::path::PathBuf;

use adw::prelude::*;
use adw::subclass::prelude::*;
use gettextrs::gettext;
use gtk::{
    gio,
    glib,
};
use log::debug;

use crate::intl::{
    self,
    MeasurementSystem,
    gettext_f,
    measurement_system,
};
use crate::model::PdfDocument;

mod imp {
    use std::cell::RefCell;

    use gtk::glib::Properties;

    use super::*;

    #[derive(Default, Properties)]
    #[properties(wrapper_type = super::Inspector)]
    pub struct Inspector {
        #[property(get, set, nullable)]
        pub(super) document: RefCell<Option<PdfDocument>>,

        pub(super) document_page: adw::PreferencesPage,
        pub(super) file_row: adw::ActionRow,
        pub(super) version_row: adw::ActionRow,
        pub(super) page_count_row: adw::ActionRow,
        pub(super) page_size_row: adw::ActionRow,
        pub(super) metadata_group: adw::PreferencesGroup,
        pub(super) author_row: adw::ActionRow,
        pub(super) title_row: adw::ActionRow,
        pub(super) subject_row: adw::ActionRow,
        pub(super) creator_row: adw::ActionRow,
        pub(super) producer_row: adw::ActionRow,
        pub(super) creation_date_row: adw::ActionRow,
        pub(super) mod_date_row: adw::ActionRow,

        pub(super) keywords_group: adw::PreferencesGroup,
        pub(super) keywords_wrap_box: adw::WrapBox,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for Inspector {
        type ParentType = adw::Bin;
        type Type = super::Inspector;

        const NAME: &'static str = "PdfInfoInspector";
    }

    #[glib::derived_properties]
    impl ObjectImpl for Inspector {
        fn constructed(&self) {
            self.parent_constructed();
            let obj = self.obj();

            Self::init_property_row(&self.file_row, &gettext("File"));

            let locate_file_button = gtk::Button::builder()
                .icon_name("system-file-manager-symbolic")
                .css_classes(["flat"])
                .valign(gtk::Align::Center)
                .tooltip_text(gettext("Open in Files"))
                .build();
            let open_file_button = gtk::Button::builder()
                .icon_name("document-open-symbolic")
                .css_classes(["flat"])
                .valign(gtk::Align::Center)
                .tooltip_text("Open file")
                .build();

            let file_row_actions = gtk::Box::new(gtk::Orientation::Horizontal, 0);
            file_row_actions.append(&locate_file_button);
            file_row_actions.append(&open_file_button);
            self.file_row.add_suffix(&file_row_actions);

            let file_group = adw::PreferencesGroup::new();
            file_group.add(&self.file_row);

            Self::init_property_row(&self.version_row, &gettext("PDF Version"));
            Self::init_property_row(&self.page_count_row, &gettext("Page Count"));
            Self::init_property_row(&self.page_size_row, &gettext("Page Size"));
            let document_group = adw::PreferencesGroup::new();
            document_group.add(&self.version_row);
            document_group.add(&self.page_count_row);
            document_group.add(&self.page_size_row);

            Self::init_property_row(&self.author_row, &gettext("Author"));
            Self::init_property_row(&self.title_row, &gettext("Title"));
            Self::init_property_row(&self.subject_row, &gettext("Subject"));
            Self::init_property_row(&self.creator_row, &gettext("Creator"));
            Self::init_property_row(&self.producer_row, &gettext("Producer"));
            Self::init_property_row(&self.creation_date_row, &gettext("Creation Date"));
            Self::init_property_row(&self.mod_date_row, &gettext("Modification Date"));

            self.metadata_group.set_visible(false);
            self.metadata_group.add(&self.author_row);
            self.metadata_group.add(&self.title_row);
            self.metadata_group.add(&self.subject_row);
            self.metadata_group.add(&self.creator_row);
            self.metadata_group.add(&self.producer_row);
            self.metadata_group.add(&self.creation_date_row);
            self.metadata_group.add(&self.mod_date_row);

            self.keywords_wrap_box.set_child_spacing(5);
            self.keywords_wrap_box.set_line_spacing(5);
            self.keywords_group.set_visible(false);
            self.keywords_group.set_title(&gettext("Keywords"));
            self.keywords_group.add(&self.keywords_wrap_box);

            self.document_page.add(&file_group);
            self.document_page.add(&document_group);
            self.document_page.add(&self.metadata_group);
            self.document_page.add(&self.keywords_group);

            obj.set_child(Some(&self.document_page));

            obj.connect_document_notify(|i| {
                i.update();
            });

            locate_file_button.connect_clicked(glib::clone!(
                #[weak]
                obj,
                move |_| {
                    obj.locate_file();
                }
            ));
            open_file_button.connect_clicked(glib::clone!(
                #[weak]
                obj,
                move |_| {
                    obj.open_file();
                }
            ));
        }
    }

    impl WidgetImpl for Inspector {
    }

    impl BinImpl for Inspector {
    }

    impl Inspector {
        fn init_property_row(row: &adw::ActionRow, title: &str) {
            row.set_title(title);
            row.set_subtitle("—");
            row.set_subtitle_lines(1);
            row.set_subtitle_selectable(true);
            row.add_css_class("property");
        }
    }
}

glib::wrapper! {
    pub struct Inspector(ObjectSubclass<imp::Inspector>)
        @extends adw::Bin, gtk::Widget,
        @implements gtk::Buildable, gtk::ConstraintTarget, gtk::Accessible;
}

impl Inspector {
    pub fn new() -> Self {
        glib::Object::builder().build()
    }

    fn update(&self) {
        let imp = self.imp();

        let document = self.document();
        let doc = document.as_ref().map(PdfDocument::document);

        imp.file_row.set_subtitle(
            &document
                .as_ref()
                .and_then(|d| {
                    let basename = d.file().basename()?;
                    Some(basename.display().to_string())
                })
                .unwrap_or_default(),
        );

        imp.version_row.set_subtitle(
            doc.map(|d| d.version().to_string())
                .unwrap_or_default()
                .as_str(),
        );
        imp.page_count_row.set_subtitle(
            doc.map(|d| d.page_count().to_string())
                .unwrap_or_default()
                .as_str(),
        );
        Self::set_optional_value(
            &imp.page_size_row,
            doc.and_then(|d| Self::format_page_size(d.page_size()))
                .as_deref(),
        );

        let metadata = doc.and_then(|d| d.metadata());
        imp.metadata_group.set_visible(metadata.is_some());
        Self::set_optional_value(&imp.author_row, metadata.and_then(|m| m.author()));
        Self::set_optional_value(&imp.title_row, metadata.and_then(|m| m.title()));
        Self::set_optional_value(&imp.subject_row, metadata.and_then(|m| m.subject()));
        Self::set_optional_value(&imp.creator_row, metadata.and_then(|m| m.creator()));
        Self::set_optional_value(&imp.producer_row, metadata.and_then(|m| m.producer()));
        Self::set_optional_value(
            &imp.creation_date_row,
            metadata
                .and_then(|m| m.creation_date())
                .and_then(Self::format_date)
                .as_deref(),
        );
        Self::set_optional_value(
            &imp.mod_date_row,
            metadata
                .and_then(|m| m.mod_date())
                .and_then(Self::format_date)
                .as_deref(),
        );

        imp.keywords_wrap_box.remove_all();
        if let Some(k) = metadata.map(|m| m.keywords()) {
            imp.keywords_group.set_visible(!k.is_empty());
            let mut k = k;
            k.sort();
            for keyword in k {
                let label = gtk::Label::builder()
                    .label(keyword)
                    .margin_top(4)
                    .margin_bottom(4)
                    .margin_start(10)
                    .margin_end(10)
                    .build();
                let label_box = gtk::Box::builder()
                    .css_classes(["card"])
                    .orientation(gtk::Orientation::Horizontal)
                    .build();
                label_box.append(&label);
                imp.keywords_wrap_box.append(&label_box);
            }
        } else {
            imp.keywords_group.set_visible(false);
        }
    }

    fn set_optional_value(row: &adw::ActionRow, value: Option<&str>) {
        row.set_subtitle(value.unwrap_or(""));
        row.set_visible(value.is_some());
    }

    fn format_date(secs: i64) -> Option<String> {
        glib::DateTime::from_unix_local(secs)
            .ok()?
            .format("%c")
            .ok()
            .map(Into::into)
    }

    fn format_page_size(ps: Option<&pdf_engine::PageSize>) -> Option<String> {
        ps.map(|ps| {
            let paper_size = match ps.paper_size {
                pdf_engine::PaperSize::A4 => gettext("A4"),
                pdf_engine::PaperSize::Letter => gettext("Letter"),
                pdf_engine::PaperSize::Custom => String::new(),
            };

            let (width, height, unit) = match measurement_system() {
                MeasurementSystem::Us => {
                    let (width_str, height_str) = (
                        intl::format_number(ps.width / 72.0, 1),
                        intl::format_number(ps.height / 72.0, 1),
                    );
                    (width_str, height_str, "in")
                }
                MeasurementSystem::Metric => {
                    let (width_str, height_str) = (
                        intl::format_number(ps.width * 25.4 / 72.0, 0),
                        intl::format_number(ps.height * 25.4 / 72.0, 0),
                    );
                    (width_str, height_str, "mm")
                }
            };
            let size = gettext_f!(
                "{width}x{height}{space}{unit}",
                width = width,
                height = height,
                space = "\u{a0}",
                unit = unit,
            );

            let orientation = match ps.orientation {
                pdf_engine::PageOrientation::Portrait => gettext("Portrait"),
                pdf_engine::PageOrientation::Landscape => gettext("Landscape"),
            };

            format!("{} ({}, {})", paper_size, size, orientation)
        })
    }

    fn locate_file(&self) {
        let Some(document) = self.document() else {
            return;
        };
        gtk::FileLauncher::new(Some(&document.file())).open_containing_folder(
            None::<&gtk::Window>,
            None::<&gio::Cancellable>,
            |result| {
                debug!("locate_file result {result:?}");
            },
        );
    }

    fn open_file(&self) {
        let Some(document) = self.document() else {
            return;
        };
        gtk::FileLauncher::new(Some(&document.file())).launch(
            None::<&gtk::Window>,
            None::<&gio::Cancellable>,
            |result| {
                debug!("locate_file result {result:?}");
            },
        );
    }
}

impl Default for Inspector {
    fn default() -> Self {
        Self::new()
    }
}
