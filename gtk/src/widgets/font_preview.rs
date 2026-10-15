// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use gettextrs::gettext;
use gtk::{
    gio,
    glib,
};

use crate::intl::gettext_f;
use crate::model::{
    PdfFont,
    PreviewFontFaces,
};
use crate::prelude::*;

const SYSTEM_FONT_PREVIEW_AREA_NAME: &str = "system-font";
const EMBEDDED_FONT_PREVIEW_AREA_NAME: &str = "embedded-font";

mod imp {
    use std::cell::{
        OnceCell,
        RefCell,
    };

    use gtk::glib::Properties;

    use super::*;
    use crate::widgets::font_preview_area::FontPreviewArea;

    #[derive(Default, Properties)]
    #[properties(wrapper_type = super::FontPreview)]
    pub struct FontPreview {
        #[property(get, construct_only)]
        pub(super) settings: OnceCell<gio::Settings>,

        #[property(get, set, nullable)]
        pub(super) font: RefCell<Option<PdfFont>>,

        pub(super) container_stack: gtk::Stack, // Switches between placeholder and font previews
        pub(super) placeholder_label: gtk::Label,
        pub(super) placeholder_box: gtk::Box,

        pub(super) font_preview_box: gtk::Box,
        pub(super) font_preview_switcher: adw::InlineViewSwitcher,
        pub(super) font_preview_stack: adw::ViewStack,

        pub(super) system_font_preview_area: OnceCell<FontPreviewArea>,
        pub(super) embedded_font_preview_area: OnceCell<FontPreviewArea>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for FontPreview {
        type ParentType = adw::Bin;
        type Type = super::FontPreview;

        const NAME: &'static str = "PdfInfoFontPreview";
    }

    #[glib::derived_properties]
    impl ObjectImpl for FontPreview {
        fn constructed(&self) {
            self.parent_constructed();
            let obj = self.obj();

            _ = self
                .system_font_preview_area
                .set(FontPreviewArea::new(self.settings.get().unwrap().clone()));
            _ = self
                .embedded_font_preview_area
                .set(FontPreviewArea::new(self.settings.get().unwrap().clone()));

            self.font_preview_switcher
                .set_display_mode(adw::InlineViewSwitcherDisplayMode::Labels);
            self.font_preview_switcher.set_halign(gtk::Align::Center);
            self.font_preview_switcher
                .set_stack(Some(&self.font_preview_stack));

            self.font_preview_stack.set_enable_transitions(true);
            _ = self.font_preview_stack.add_titled(
                self.system_font_preview_area.get().unwrap(),
                Some(SYSTEM_FONT_PREVIEW_AREA_NAME),
                &gettext("System Font"),
            );
            _ = self.font_preview_stack.add_titled(
                self.embedded_font_preview_area.get().unwrap(),
                Some(EMBEDDED_FONT_PREVIEW_AREA_NAME),
                &gettext("Embedded Font"),
            );
            self.font_preview_box
                .set_orientation(gtk::Orientation::Vertical);
            self.font_preview_box.set_spacing(10);
            self.font_preview_box.append(&self.font_preview_switcher);
            self.font_preview_box.append(&self.font_preview_stack);

            // placeholder
            {
                let preview_placeholder_icon = gtk::Image::builder()
                    .icon_name("font-x-generic-symbolic")
                    .pixel_size(32)
                    .build();
                self.placeholder_box.add_css_class("dim-label");
                self.placeholder_box
                    .set_orientation(gtk::Orientation::Vertical);
                self.placeholder_box.set_spacing(5);
                self.placeholder_box.set_halign(gtk::Align::Center);
                self.placeholder_box.set_valign(gtk::Align::Center);
                self.placeholder_box.append(&preview_placeholder_icon);
                self.placeholder_box.append(&self.placeholder_label);
            }
            self.container_stack.set_margin_top(10);
            self.container_stack.set_margin_bottom(10);
            self.container_stack.set_margin_start(10);
            self.container_stack.set_margin_end(10);
            self.container_stack.add_child(&self.font_preview_box);
            self.container_stack.add_child(&self.placeholder_box);

            obj.set_child(Some(&self.container_stack));

            obj.connect_font_notify(|f| f.on_font_updated());

            obj.on_font_updated();
        }
    }

    impl BinImpl for FontPreview {
    }
    impl WidgetImpl for FontPreview {
    }
}

glib::wrapper! {
    pub struct FontPreview(ObjectSubclass<imp::FontPreview>)
        @extends adw::Bin, gtk::Widget,
        @implements gtk::Buildable, gtk::ConstraintTarget, gtk::Accessible;
}

impl FontPreview {
    pub fn new(settings: gio::Settings) -> Self {
        glib::Object::builder()
            .property("settings", settings)
            .build()
    }

    fn on_font_updated(&self) {
        let imp = self.imp();
        let system_font_preview_area = imp
            .system_font_preview_area
            .get()
            .unwrap_or_else(|| panic!("system_font_preview_area not set"));
        let embedded_font_preview_area = imp
            .embedded_font_preview_area
            .get()
            .unwrap_or_else(|| panic!("embedded_font_preview_area not set"));

        // Reset
        imp.container_stack.set_visible_child(&imp.placeholder_box);
        let Some(font) = self.font() else {
            imp.placeholder_label
                .set_label(&gettext("Select a font to preview"));
            return;
        };
        if let Some(font_name) = font.font().display_name() {
            imp.placeholder_label.set_label(&gettext_f!(
                "No preview available for {font_name}",
                font_name = font_name
            ));
        } else {
            imp.placeholder_label
                .set_label(&gettext("No preview available"));
        }
        system_font_preview_area.set_font_face(None::<cairo::FontFace>);
        embedded_font_preview_area.set_font_face(None::<cairo::FontFace>);


        // now set the the state
        if let Some(preview_faces) = PreviewFontFaces::load(font.font()) {
            system_font_preview_area.set_font_face(preview_faces.system_font_face.clone());
            embedded_font_preview_area.set_font_face(preview_faces.embedded_font_face.clone());

            if preview_faces.system_font_face.is_some()
                || preview_faces.embedded_font_face.is_some()
            {
                imp.container_stack.set_visible_child(&imp.font_preview_box);
            }

            imp.font_preview_stack
                .page(imp.system_font_preview_area.get().unwrap())
                .set_visible(preview_faces.system_font_face.is_some());
            imp.font_preview_stack
                .page(imp.embedded_font_preview_area.get().unwrap())
                .set_visible(preview_faces.embedded_font_face.is_some());
        };
    }
}
