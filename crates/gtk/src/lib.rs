// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use gtk::prelude::*;
use gtk::{
    gio,
    glib,
};
use log::error;

use crate::app::App;

mod app;
mod config;
mod intl;
mod model;
mod prelude;
mod settings;
mod widgets;


pub fn run() -> u8 {
    #[cfg(debug_assertions)]
    unsafe {
        glib::ffi::g_log_set_debug_enabled(glib::ffi::GTRUE)
    };
    log::set_logger(&GLIB_LOGGER).expect("logger already set");

    if let Err(err) = intl::init(config::GETTEXT_PACKAGE, config::LOCALEDIR) {
        error!("Error initializing the internationalization system: {err}");
        debug_assert!(false);
        // Continue
    }
    gio::resources_register_include!("pdfinfo.gresource").expect("Failed to register resources");

    let app = App::new();
    app.run().get()
}

static GLIB_LOGGER: glib::GlibLogger = glib::GlibLogger::new(
    glib::GlibLoggerFormat::LineAndFile,
    glib::GlibLoggerDomain::CrateTarget,
);
