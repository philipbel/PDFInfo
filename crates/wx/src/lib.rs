// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use crate::app::App;

mod app;
mod font;
mod icon;
mod models;
mod views;

pub(crate) use icon::Icon;

pub fn run() {
    // TODO: Translations
    wxdragon::main(|_| {
        let app = App::new();
        app.run();
    })
    .expect("main failed");
}
