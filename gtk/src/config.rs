// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

pub const APP_ID: &str = "com.github.philipbel.PDFInfo";
pub const APP_NAME: &str = "PDF Info";
pub const GETTEXT_PACKAGE: &str = "pdfinfo";

// Set PDFINFO_LOCALEDIR at build time for installs; dev falls back to target/locale.
pub const LOCALEDIR: &str = match option_env!("PDFINFO_LOCALEDIR") {
    Some(dir) => dir,
    None => concat!(env!("CARGO_MANIFEST_DIR"), "/../target/locale"),
};

pub const DOCUMENT_WINDOW_WIDTH: i32 = 800;
pub const DOCUMENT_WINDOW_HEIGHT: i32 = 600;
pub const DOCUMENT_WINDOW_MIN_WIDTH: i32 = 600;
pub const DOCUMENT_WINDOW_MIN_HEIGHT: i32 = 400;
pub const DOCUMENT_WINDOW_WIDTH_BREAKPOINT: f64 = 700.0;

pub const DOCUMENT_WINDOW_MIN_SIDEBAR_WIDTH: f64 = 300.0;
pub const DOCUMENT_WINDOW_MAX_SIDEBAR_WIDTH: f64 = 500.0;
