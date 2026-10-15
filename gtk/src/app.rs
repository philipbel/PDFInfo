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

use crate::config;
use crate::widgets::{
    MainWindow,
    PreferencesDialog,
    actions,
};

mod imp {


    use super::*;
    use crate::widgets::MainWindow;

    pub struct App {
        pub settings: gio::Settings,
    }

    impl Default for App {
        fn default() -> Self {
            Self {
                settings: Self::new_settings(),
            }
        }
    }

    #[glib::object_subclass]
    impl ObjectSubclass for App {
        type ParentType = adw::Application;
        type Type = super::App;

        const NAME: &'static str = "PdfInfoApp";
    }

    impl ObjectImpl for App {
    }

    impl ApplicationImpl for App {
        fn startup(&self) {
            self.parent_startup();

            let app = self.obj();
            app.setup_actions();
            app.setup_accels();
        }

        fn shutdown(&self) {
            self.parent_shutdown();
            gio::Settings::sync();
        }

        fn activate(&self) {
            self.parent_activate();

            let obj = self.obj();

            let window = obj
                .active_window()
                .unwrap_or_else(|| MainWindow::new(&*obj, self.settings.clone()).into());
            window.present();
        }

        fn open(&self, files: &[gio::File], hint: &str) {
            self.parent_open(files, hint);
            let obj = self.obj();
            // Reuse empty windows to open requested files
            let mut empty_windows: Vec<MainWindow> = obj
                .windows()
                .into_iter()
                .filter_map(|w| w.downcast::<MainWindow>().ok())
                .filter(|w| w.document().is_none())
                .collect();
            files.iter().for_each(|f| {
                let window = empty_windows
                    .pop()
                    .unwrap_or_else(|| MainWindow::new(&*obj, self.settings.clone()));
                window.open_file(f.clone());
                window.present();
            });
        }
    }

    impl GtkApplicationImpl for App {
    }

    impl AdwApplicationImpl for App {
    }

    impl App {
        fn new_settings() -> gio::Settings {
            // Load from PDFINFO_SCHEMA_DIR directory during development
            #[cfg(debug_assertions)]
            {
                let source = gio::SettingsSchemaSource::from_directory(
                    env!("PDFINFO_SCHEMA_DIR"),
                    gio::SettingsSchemaSource::default().as_ref(),
                    false,
                )
                .expect("could not load settings schema via env PDFINFO_SCHEMA_DIR");
                let schema = source
                    .lookup(config::APP_ID, false)
                    .expect("settings schema not found");
                gio::Settings::new_full(&schema, None::<&gio::SettingsBackend>, None)
            }
            // Load from system directories
            #[cfg(not(debug_assertions))]
            gio::Settings::new(config::APP_ID)
        }
    }
}

glib::wrapper! {
    pub struct App(ObjectSubclass<imp::App>)
        @extends adw::Application, gtk::Application, gio::Application,
        @implements gio::ActionGroup, gio::ActionMap;
}

impl Default for App {
    fn default() -> Self {
        glib::Object::builder()
            .property("application-id", config::APP_ID)
            .property("resource-base-path", "/com/github/philipbel/PDFInfo")
            .property("flags", gio::ApplicationFlags::HANDLES_OPEN)
            .build()
    }
}

impl App {
    pub fn new() -> Self {
        Self::default()
    }

    fn setup_actions(&self) {
        self.add_action_entries([
            gio::ActionEntry::builder(actions::ABOUT)
                .activate(|app: &Self, _, _| app.show_about())
                .build(),
            gio::ActionEntry::builder(actions::PREFERENCES)
                .activate(|app: &Self, _, _| app.show_preferences())
                .build(),
            gio::ActionEntry::builder(actions::NEW_WINDOW)
                .activate(|app: &Self, _, _| app.new_window())
                .build(),
            gio::ActionEntry::builder(actions::QUIT)
                .activate(|app: &App, _, _| {
                    // Gracefully quite: close all windows first
                    for window in app.windows() {
                        window.close();
                    }
                })
                .build(),
            gio::ActionEntry::builder(actions::SHORTCUTS)
                .activate(|app: &Self, _, _| app.show_shortcuts())
                .build(),
        ]);
    }

    fn setup_accels(&self) {
        self.set_accels_for_action(actions::WIN_OPEN, &[actions::ACCEL_OPEN]);
        self.set_accels_for_action(
            actions::WIN_TOGGLE_INSPECTOR,
            &[actions::ACCEL_TOGGLE_INSPECTOR],
        );
        self.set_accels_for_action(
            actions::WIN_TOGGLE_PREVIEW,
            &[actions::ACCEL_TOGGLE_PREVIEW],
        );
        self.set_accels_for_action(actions::APP_PREFERENCES, &[actions::ACCEL_PREFERENCES]);
        self.set_accels_for_action(actions::APP_SHORTCUTS, &[actions::ACCEL_SHORTCUTS]);
        self.set_accels_for_action(actions::WINDOW_CLOSE, &[actions::ACCEL_WINDOW_CLOSE]);
        self.set_accels_for_action(actions::APP_NEW_WINDOW, &[actions::ACCEL_NEW_WINDOW]);
        self.set_accels_for_action(actions::APP_QUIT, &[actions::ACCEL_QUIT]);
    }

    fn show_about(&self) {
        let dialog = adw::AboutDialog::builder()
            .application_name(config::APP_NAME)
            .version(env!("CARGO_PKG_VERSION"))
            .license_type(gtk::License::MitX11)
            .website("https://github.com/philipbel/PDFInfo")
            .issue_url("https://github.com/philipbel/PDFInfo/issues")
            .comments(gettext("Inspect the fonts in PDF documents"))
            .build();
        dialog.present(self.active_window().as_ref());
    }

    fn show_preferences(&self) {
        PreferencesDialog::new(self.imp().settings.clone()).present(self.active_window().as_ref());
    }

    fn new_window(&self) {
        MainWindow::new(self, self.imp().settings.clone()).present();
    }

    fn show_shortcuts(&self) {
        let general_section = adw::ShortcutsSection::new(Some(&gettext("General")));
        for (title, action) in [
            (
                gettext(actions::TOOLTIP_NEW_WINDOW),
                actions::APP_NEW_WINDOW,
            ),
            (gettext(actions::TOOLTIP_OPEN), actions::WIN_OPEN),
            (
                gettext(actions::TOOLTIP_WINDOW_CLOSE),
                actions::WINDOW_CLOSE,
            ),
            (
                gettext("Show or hide the inspector"),
                actions::WIN_TOGGLE_INSPECTOR,
            ),
            (gettext("Show preferences"), actions::APP_PREFERENCES),
            (gettext("Show keyboard shortcuts"), actions::APP_SHORTCUTS),
            (gettext(actions::TOOLTIP_QUIT), actions::APP_QUIT),
        ] {
            let shortcut = adw::ShortcutsItem::from_action(&title, action);
            general_section.add(shortcut);
        }
        let dialog = adw::ShortcutsDialog::new();
        dialog.add(general_section);
        dialog.present(self.active_window().as_ref());
    }
}
