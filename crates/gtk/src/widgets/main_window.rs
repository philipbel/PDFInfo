use std::cell::{
    OnceCell,
    RefCell,
};

use adw::prelude::*;
use adw::subclass::prelude::*;
use gettextrs::gettext;
use gtk::gio::{
    self,
    File,
};
use gtk::glib;

use crate::config;
use crate::model::PdfDocument;
use crate::settings::{
    SettingsExtensions,
    schema_keys,
};
use crate::widgets::{
    FontList,
    Inspector,
};

mod imp {
    use super::*;
    use crate::widgets::{
        FontPreview,
        actions,
    };

    #[derive(Default, glib::Properties)]
    #[properties(wrapper_type = super::MainWindow)]
    pub struct MainWindow {
        #[property(get, construct_only)]
        pub(super) settings: OnceCell<gio::Settings>,
        #[property(get, set, nullable)]
        pub(super) document: RefCell<Option<PdfDocument>>,

        pub(super) header_bar: adw::HeaderBar,
        pub(super) font_preview_revealer: gtk::Revealer,
        pub(super) toolbar_view: adw::ToolbarView,
        pub(super) window_title: adw::WindowTitle,
        pub(super) placeholder: adw::StatusPage,
        pub(super) inspector_button: gtk::ToggleButton,
        pub(super) preview_button: gtk::ToggleButton,
        pub(super) font_list: FontList,
        pub(super) inspector: Inspector,
        pub(super) split_view: adw::OverlaySplitView,
        pub(super) font_list_stack: gtk::Stack,
        pub(super) font_preview: OnceCell<FontPreview>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for MainWindow {
        type ParentType = adw::ApplicationWindow;
        type Type = super::MainWindow;

        const NAME: &'static str = "PdfInfoMainWindow";
    }

    #[glib::derived_properties]
    impl ObjectImpl for MainWindow {
        fn constructed(&self) {
            self.parent_constructed();
            let obj = self.obj();

            // Set up first
            _ = self.font_preview.set(FontPreview::new(
                self.settings
                    .get()
                    .expect("settings must be set in new")
                    .clone(),
            ));
            self.init_ui();

            // Actions & bindings
            obj.add_action(&gio::PropertyAction::new(
                actions::TOGGLE_INSPECTOR,
                &self.split_view,
                "show-sidebar",
            ));
            obj.add_action(&gio::PropertyAction::new(
                actions::TOGGLE_PREVIEW,
                &self.font_preview_revealer,
                "reveal-child",
            ));
            obj.add_action_entries([gio::ActionEntry::builder(actions::OPEN)
                .activate(|window: &super::MainWindow, _, _| {
                    window.show_open_dialog();
                })
                .build()]);
            obj.connect_document_notify(|this| {
                this.update();
            });
            self.font_list
                .bind_property("selected-font", self.font_preview.get().unwrap(), "font")
                .sync_create()
                .build();
            // No binding for the sidebar, because the breakpoint changes it. Save manually on close
            obj.connect_close_request(|window| {
                let imp = window.imp();
                let settings = imp.settings.get().unwrap();
                if !imp.split_view.is_collapsed() {
                    settings.set_value_for_key(
                        schema_keys::SHOW_INSPECTOR,
                        imp.split_view.shows_sidebar(),
                    );
                }
                glib::Propagation::Proceed
            });
            self.settings
                .get()
                .unwrap()
                .bind(
                    schema_keys::SHOW_PREVIEW.name(),
                    &self.font_preview_revealer,
                    "reveal-child",
                )
                .flags(
                    gio::SettingsBindFlags::GET
                        | gio::SettingsBindFlags::GET_NO_CHANGES // Don't update when other windows change
                        | gio::SettingsBindFlags::SET,
                )
                .build();

            obj.update();
        }
    }

    impl WidgetImpl for MainWindow {
    }
    impl WindowImpl for MainWindow {
    }
    impl ApplicationWindowImpl for MainWindow {
    }
    impl AdwApplicationWindowImpl for MainWindow {
    }

    impl MainWindow {
        fn init_ui(&self) {
            let obj = self.obj();

            self.init_window();
            self.init_header_bar();
            self.init_toolbar_view();
            self.init_content();

            // Breakpoint
            let breakpoint = adw::Breakpoint::new(adw::BreakpointCondition::new_length(
                adw::BreakpointConditionLengthType::MaxWidth,
                config::DOCUMENT_WINDOW_WIDTH_BREAKPOINT,
                adw::LengthUnit::Px,
            ));
            breakpoint.add_setter(&self.split_view, "collapsed", Some(&true.to_value()));
            breakpoint.add_setter(&self.split_view, "show-sidebar", Some(&false.to_value()));
            obj.add_breakpoint(breakpoint);

            // Toolbar (main content)
            obj.set_content(Some(&self.toolbar_view));
        }

        fn init_window(&self) {
            let obj = self.obj();
            obj.set_title(Some(config::APP_NAME));
            obj.set_default_width(config::DOCUMENT_WINDOW_WIDTH);
            obj.set_default_height(config::DOCUMENT_WINDOW_HEIGHT);
            obj.set_width_request(config::DOCUMENT_WINDOW_MIN_WIDTH);
            obj.set_height_request(config::DOCUMENT_WINDOW_MIN_HEIGHT);
        }

        fn init_content(&self) {
            let preview_vbox = gtk::Box::new(gtk::Orientation::Vertical, 0);
            preview_vbox.append(&gtk::Separator::new(gtk::Orientation::Horizontal));
            preview_vbox.append(self.font_preview.get().unwrap());

            self.font_preview_revealer
                .set_transition_type(gtk::RevealerTransitionType::SlideDown);
            self.font_preview_revealer.set_transition_duration(200);
            self.font_preview_revealer.set_child(Some(&preview_vbox));

            // Main area
            self.font_list_stack
                .set_transition_type(gtk::StackTransitionType::Crossfade);
            self.font_list_stack.set_vexpand(true);
            self.font_list_stack.add_child(&self.placeholder);
            self.font_list_stack.add_child(&self.font_list);

            let content_container = gtk::Box::new(gtk::Orientation::Vertical, 0);
            content_container.append(&self.font_list_stack);
            content_container.append(&self.font_preview_revealer);

            self.placeholder
                .set_icon_name(Some("x-office-document-symbolic"));
            self.placeholder.set_title(&gettext("No Document"));
            self.placeholder
                .set_description(Some(&gettext("Open a PDF to inspect its fonts")));

            // Initial value
            self.split_view.set_show_sidebar(
                self.settings
                    .get()
                    .unwrap()
                    .boolean(schema_keys::SHOW_INSPECTOR.name()),
            );
            self.split_view.set_sidebar_position(gtk::PackType::End);
            self.split_view
                .set_min_sidebar_width(config::DOCUMENT_WINDOW_MIN_SIDEBAR_WIDTH);
            self.split_view
                .set_max_sidebar_width(config::DOCUMENT_WINDOW_MAX_SIDEBAR_WIDTH);
            self.split_view.set_content(Some(&content_container));
            self.split_view.set_sidebar(Some(&self.inspector));

            self.update_inspector_button_tooltip();
            self.split_view.connect_show_sidebar_notify(glib::clone!(
                #[weak(rename_to = window)]
                self,
                move |_split_view| {
                    window.update_inspector_button_tooltip();
                }
            ));
            self.update_preview_button_tooltip();
            self.font_preview_revealer
                .connect_reveal_child_notify(glib::clone!(
                    #[weak(rename_to = window)]
                    self,
                    move |_revealer| {
                        window.update_preview_button_tooltip();
                    }
                ));
        }

        fn init_toolbar_view(&self) {
            self.toolbar_view.add_top_bar(&self.header_bar);
            self.toolbar_view.set_content(Some(&self.split_view));
        }

        fn init_header_bar(&self) {
            // See https://keenlycode.github.io/gnomicon/ for icons

            self.window_title.set_title(config::APP_NAME);
            self.inspector_button
                .set_icon_name("sidebar-show-right-symbolic");
            self.inspector_button
                .set_action_name(Some(actions::WIN_TOGGLE_INSPECTOR));
            self.preview_button.set_icon_name("font-x-generic-symbolic");
            self.preview_button
                .set_action_name(Some(actions::WIN_TOGGLE_PREVIEW));

            let main_menu = Self::build_main_menu();
            let main_menu_button = gtk::MenuButton::builder()
                .icon_name("open-menu-symbolic")
                .tooltip_text(gettext("Main Menu"))
                .menu_model(&main_menu)
                .primary(true)
                .build();
            let new_button = gtk::Button::builder()
                .icon_name("window-new-symbolic")
                .tooltip_text(gettext(actions::TOOLTIP_NEW_WINDOW))
                .action_name(actions::APP_NEW_WINDOW)
                .build();
            let open_button = gtk::Button::builder()
                .icon_name("document-open-symbolic")
                .tooltip_text(gettext(actions::TOOLTIP_OPEN))
                .action_name(actions::WIN_OPEN)
                .build();

            self.header_bar.set_title_widget(Some(&self.window_title));
            self.header_bar.pack_start(&new_button);
            self.header_bar.pack_start(&open_button);
            self.header_bar.pack_end(&main_menu_button);
            self.header_bar.pack_end(&self.inspector_button);
            self.header_bar.pack_end(&self.preview_button);
        }

        fn build_main_menu() -> gio::Menu {
            let window_section = gio::Menu::new();
            window_section.append(Some(&gettext("_New Window")), Some(actions::APP_NEW_WINDOW));
            window_section.append(Some(&gettext("_Close Window")), Some(actions::WINDOW_CLOSE));

            let app_section = gio::Menu::new();
            app_section.append(
                Some(&gettext("_Preferences")),
                Some(actions::APP_PREFERENCES),
            );
            app_section.append(
                Some(&gettext("_Keyboard Shortcuts")),
                Some(actions::APP_SHORTCUTS),
            );
            app_section.append(Some(&gettext("_About PDF Info")), Some(actions::APP_ABOUT));

            let main_menu = gio::Menu::new();
            main_menu.append_section(None, &window_section);
            main_menu.append_section(None, &app_section);

            main_menu
        }

        fn update_inspector_button_tooltip(&self) {
            let tip = if self.split_view.shows_sidebar() {
                gettext("Hide the document inspector")
            } else {
                gettext("Show the document inspector")
            };
            self.inspector_button.set_tooltip_text(Some(&tip));
        }

        fn update_preview_button_tooltip(&self) {
            let tip = if self.font_preview_revealer.reveals_child() {
                gettext("Hide the font preview")
            } else {
                gettext("Show the font preview")
            };
            self.preview_button.set_tooltip_text(Some(&tip));
        }
    }
}

glib::wrapper! {
    pub struct MainWindow(ObjectSubclass<imp::MainWindow>)
        @extends adw::ApplicationWindow, gtk::ApplicationWindow, gtk::Window, gtk::Widget,
        @implements gio::ActionMap, gio::ActionGroup, gtk::Native, gtk::Root, gtk::Accessible, gtk::Buildable, gtk::ConstraintTarget, gtk::ShortcutManager;
}

impl MainWindow {
    pub fn new<A: IsA<gtk::Application>>(app: &A, settings: gio::Settings) -> Self {
        glib::Object::builder()
            .property("application", app)
            .property("settings", settings)
            .build()
    }

    pub fn open_file(&self, file: File) {
        glib::spawn_future_local(glib::clone!(
            #[weak(rename_to = window)]
            self,
            async move {
                match PdfDocument::from_file(file).await {
                    Ok(document) => window.set_document(Some(document)),
                    Err(err) => {
                        // TODO: Show error
                    }
                };
            }
        ));
    }

    fn update(&self) {
        let imp = self.imp();
        let document = self.document();

        imp.inspector.set_document(document.clone());
        imp.font_list.set_document(document.clone());

        let file = document.as_ref().map(PdfDocument::file);

        let name = file
            .as_ref()
            .and_then(gio::File::basename)
            .map(|p| p.display().to_string())
            .unwrap_or_else(|| config::APP_NAME.to_string());
        let folder = file
            .as_ref()
            .and_then(gio::File::parent)
            .as_ref()
            .and_then(File::path)
            .map(|p| p.display().to_string())
            .unwrap_or_default();

        if document.is_some() {
            imp.font_list_stack.set_visible_child(&imp.font_list);
            imp.font_preview_revealer.set_visible(true);
        } else {
            imp.font_list_stack.set_visible_child(&imp.placeholder);
            imp.font_preview_revealer.set_visible(false);
        }

        self.set_title(Some(&name));
        imp.window_title.set_title(&name);
        imp.window_title.set_subtitle(&folder);
    }

    fn show_open_dialog(&self) {
        let pdf_filter = gtk::FileFilter::new();
        pdf_filter.set_name(Some(&gettext("PDF Documents")));
        pdf_filter.add_mime_type("application/pdf");
        pdf_filter.add_suffix("pdf");

        let filters = gio::ListStore::new::<gtk::FileFilter>();
        filters.append(&pdf_filter);

        let dialog = gtk::FileDialog::builder()
            .title(gettext("Open PDF"))
            .modal(true)
            .filters(&filters)
            .default_filter(&pdf_filter)
            .build();

        dialog.open(
            Some(self),
            gio::Cancellable::NONE,
            glib::clone!(
                #[weak(rename_to=window)]
                self,
                move |result| {
                    let Ok(file) = result else { return };
                    window.open_file(file);
                }
            ),
        );
    }
}
