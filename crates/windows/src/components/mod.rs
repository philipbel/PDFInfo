// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

#[cfg(debug_assertions)]
use windows_reactor::Color;


mod document;
mod font_list;
mod inspector;
mod placeholder;
mod root;

pub(crate) use root::RootComponent;

#[cfg(debug_assertions)]
pub(crate) fn random_color() -> Color {
    use rand::{
        self,
        RngExt as _,
    };
    Color::rgb(
        rand::rng().random(),
        rand::rng().random(),
        rand::rng().random(),
    )
}
