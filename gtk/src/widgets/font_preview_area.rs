// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::cell::{
    Cell,
    OnceCell,
    RefCell,
};
use std::cmp::max;

use glib::Properties;
use gtk::{
    gio,
    glib,
};

use crate::prelude::*;

const DRAWING_AREA_PADDING: f64 = 10.0;


mod imp {
    use log::warn;

    use super::*;
    use crate::settings::schema_keys;

    #[derive(Default, Properties)]
    #[properties(wrapper_type = super::FontPreviewArea)]
    pub struct FontPreviewArea {
        #[property(get, set, nullable)]
        pub(super) font_face: RefCell<Option<cairo::FontFace>>,
        #[property(get, set)]
        pub(super) font_preview_size: Cell<i32>,
        #[property(get, set)]
        pub(super) font_preview_text: RefCell<String>,
        #[property(get, construct_only)]
        pub(super) settings: OnceCell<gio::Settings>,

        pub(super) drawing_area: gtk::DrawingArea,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for FontPreviewArea {
        type ParentType = adw::Bin;
        type Type = super::FontPreviewArea;

        const NAME: &'static str = "PdfInfoFontPreviewArea";
    }

    #[glib::derived_properties]
    impl ObjectImpl for FontPreviewArea {
        fn constructed(&self) {
            self.parent_constructed();
            let obj = self.obj();
            let settings = self.settings.get().expect("no settings set");

            self.drawing_area.add_css_class("font-preview-area");
            obj.set_child(Some(&self.drawing_area));

            self.drawing_area.set_draw_func(glib::clone!(
                #[weak(rename_to = this)]
                self,
                move |_, cr, w, h| {
                    _ = this
                        .obj()
                        .draw_preview(cr, w, h)
                        .inspect_err(|e| warn!("Failed to draw font preview: {e}"));
                }
            ));
            obj.connect_font_preview_size_notify(super::FontPreviewArea::update);
            obj.connect_font_preview_text_notify(|f| {
                f.imp()
                    .drawing_area
                    .update_property(&[gtk::accessible::Property::Label(
                        &f.imp().font_preview_text.borrow(),
                    )]);
                f.update();
            });
            obj.connect_font_face_notify(super::FontPreviewArea::update);
            settings
                .bind(
                    schema_keys::PREVIEW_FONT_TEXT.name(),
                    &*obj,
                    "font-preview-text",
                )
                .build();
            settings
                .bind(
                    schema_keys::PREVIEW_FONT_SIZE.name(),
                    &*obj,
                    "font-preview-size",
                )
                .build();
        }
    }

    impl BinImpl for FontPreviewArea {
    }
    impl WidgetImpl for FontPreviewArea {
    }

    impl FontPreviewArea {
    }
}

glib::wrapper! {
    pub struct FontPreviewArea(ObjectSubclass<imp::FontPreviewArea>)
        @extends adw::Bin, gtk::Widget,
        @implements gtk::Buildable, gtk::ConstraintTarget, gtk::Accessible;
}


impl FontPreviewArea {
    pub fn new(settings: gio::Settings) -> Self {
        glib::Object::builder()
            .property("settings", settings)
            .build()
    }

    fn update(&self) {
        self.update_preview_height();
        self.imp().drawing_area.queue_draw();
    }

    fn draw_preview(
        &self,
        cr: &cairo::Context,
        width: i32,
        height: i32,
    ) -> Result<(), cairo::Error> {
        let imp = self.imp();
        let text = self.font_preview_text();
        // Select the face
        let Some(font_face) = imp.font_face.borrow().clone() else {
            return Ok(());
        };
        cr.set_font_face(&font_face);

        let foreground_color = imp.drawing_area.color();
        cr.set_source_rgba(
            foreground_color.red() as f64,
            foreground_color.green() as f64,
            foreground_color.blue() as f64,
            foreground_color.alpha() as f64,
        );
        cr.set_font_size(self.font_preview_size() as f64);

        let extents = cr.text_extents(&text)?;
        let x = (width as f64 - extents.width()) / 2.0 - extents.x_bearing();
        let y = (height as f64 - extents.height()) / 2.0 - extents.y_bearing();
        cr.move_to(x, y);

        cr.show_text(&text)?;
        Ok(())
    }

    fn update_preview_height(&self) {
        let imp = self.imp();
        let height = self.measure_preview_height();
        imp.drawing_area.set_content_height(height);
    }

    fn measure_preview_height(&self) -> i32 {
        let imp = self.imp();
        let mut height = 50; // TODO: Fix
        if let Some(font_face) = imp.font_face.borrow().clone()
            && let Ok(h) = self.measure_preview_height_for_font_face(&font_face)
        {
            height = max(height, h);
        }
        height
    }

    fn measure_preview_height_for_font_face(
        &self,
        face: &cairo::FontFace,
    ) -> Result<i32, cairo::Error> {
        let font_matrix = cairo::Matrix::new(
            self.font_preview_size() as f64,
            0.0,
            0.0,
            self.font_preview_size() as f64,
            0.0,
            0.0,
        );
        let scaled_font = cairo::ScaledFont::new(
            face,
            &font_matrix,
            &cairo::Matrix::identity(),
            &cairo::FontOptions::new()?,
        )?;
        let font_extents = scaled_font.extents();
        let text_extents = scaled_font.text_extents(&self.font_preview_text());
        let font_height = font_extents.height().max(text_extents.height());
        let height = (font_height + 2.0 * DRAWING_AREA_PADDING).ceil() as i32;
        Ok(height)
    }
}
