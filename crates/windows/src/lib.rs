// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT


use font_locator::FontInfo;
use windows_reactor::App;

use crate::components::RootComponent;

mod components;
mod models;


pub fn run() {
    App::run_component::<RootComponent>(()).unwrap();
}
