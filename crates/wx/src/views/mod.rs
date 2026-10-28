// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

mod document_view;
mod font_list_view;
mod icon_view;
mod main_view;
mod placeholder_view;
mod view;


pub(crate) use document_view::DocumentView;
pub(crate) use main_view::MainView;
pub(crate) use placeholder_view::PlaceholderView;
pub(crate) use view::View;


fn random_color() -> wxdragon::Colour {
    wxdragon::Colour {
        r: rand::random(),
        g: rand::random(),
        b: rand::random(),
        a: 255,
    }
}
