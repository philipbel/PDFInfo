// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

mod document_view;
mod main_view;
mod no_content_view;
mod view;

pub(crate) use document_view::{
    DocumentError,
    DocumentView,
};
pub(crate) use main_view::MainView;
pub(crate) use no_content_view::NoContentView;
pub(crate) use view::View;
