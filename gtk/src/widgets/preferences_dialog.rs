// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use adw::prelude::*;
use adw::subclass::prelude::*;
use gettextrs::gettext;
use gtk::{
    gio,
    glib,
};

use crate::settings::SettingsExtensions;


mod imp {
    use std::cell::OnceCell;

    use glib::Properties;

    use super::*;
    use crate::settings::schema_keys;

    #[derive(Default, Properties)]
    #[properties(wrapper_type = super::PreferencesDialog)]
    pub struct PreferencesDialog {
        #[property(get, construct_only)]
        pub(super) settings: OnceCell<gio::Settings>,
        pub(super) general_page: adw::PreferencesPage,
        pub(super) font_preview_group: adw::PreferencesGroup,
        pub(super) font_preview_text: adw::EntryRow,
        pub(super) font_preview_size: adw::SpinRow,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for PreferencesDialog {
        type ParentType = adw::PreferencesDialog;
        type Type = super::PreferencesDialog;

        const NAME: &'static str = "PdfInfoPreferencesDialog";
    }

    #[glib::derived_properties]
    impl ObjectImpl for PreferencesDialog {
        fn constructed(&self) {
            self.parent_constructed();
            let obj = self.obj();

            self.general_page.set_title(&gettext("General"));
            self.font_preview_group.set_title(&gettext("Font Preview"));
            self.font_preview_text.set_title(&gettext("Preview Text"));
            self.font_preview_size
                .set_title(&gettext("Preview Font Size"));

            self.font_preview_group.add(&self.font_preview_text);
            self.font_preview_group.add(&self.font_preview_size);
            self.general_page.add(&self.font_preview_group);
            obj.add(&self.general_page);

            let settings = self.settings.get().expect("no settings set");

            if let Some(font_size_range) = self
                .settings
                .get()
                .map(|s| s.range(schema_keys::PREVIEW_FONT_SIZE))
            {
                self.font_preview_size.set_range(
                    f64::from(*font_size_range.start()),
                    f64::from(*font_size_range.end()),
                );
            }
            self.font_preview_size.adjustment().set_step_increment(1.0);

            settings
                .bind(
                    schema_keys::PREVIEW_FONT_TEXT.name(),
                    &self.font_preview_text,
                    "text",
                )
                .build();
            settings
                .bind(
                    schema_keys::PREVIEW_FONT_SIZE.name(),
                    &self.font_preview_size,
                    "value",
                )
                .build();
        }
    }

    impl WidgetImpl for PreferencesDialog {
    }
    impl AdwDialogImpl for PreferencesDialog {
    }
    impl PreferencesDialogImpl for PreferencesDialog {
    }

    impl PreferencesDialog {
    }
}

glib::wrapper! {
    pub struct PreferencesDialog(ObjectSubclass<imp::PreferencesDialog>)
        @extends adw::PreferencesDialog, adw::Dialog, gtk::Widget,
        @implements gtk::Buildable, gtk::ConstraintTarget, gtk::ShortcutManager, gtk::Accessible;
}

impl PreferencesDialog {
    pub fn new(settings: gio::Settings) -> Self {
        glib::Object::builder()
            .property("settings", settings)
            .build()
    }
}
