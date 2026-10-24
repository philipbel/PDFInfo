// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT


#![cfg_attr(target_os = "windows", windows_subsystem = "windows")]


// GTK is the default on Linux
#[cfg(all(any(feature = "gtk", target_os = "linux"), not(feature = "wx")))]
fn main() {
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("trace")).init();
    pdfinfo_gtk::run();
}

// WxWidgets is the default on Windows
// We also make it the default here on macOS for testing purposes
#[cfg(all(
    not(feature = "gtk"),
    any(feature = "wx", target_os = "windows", target_os = "macos")
))]
fn main() {
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("trace")).init();
    pdfinfo_wx::run();
}
