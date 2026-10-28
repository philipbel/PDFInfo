// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT


#![cfg_attr(target_os = "windows", windows_subsystem = "windows")]


fn main() {
    platform_main();
}

fn init_logging(extra_filters: &[&str]) {
    let default_filter = if cfg!(debug_assertions) {
        "trace"
    } else {
        "warn"
    };
    let mut filters = vec![default_filter];
    filters.extend_from_slice(extra_filters);
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or(filters.join(",")))
        .init();
}

// GTK is the default on Linux
#[cfg(all(any(feature = "gtk", target_os = "linux"), not(feature = "wx")))]
fn platform_main() {
    init_logging(&[]);
    pdfinfo_gtk::run();
}

// WxWidgets is the default on Windows
// We also make it the default here on macOS for testing purposes
#[cfg(all(
    not(feature = "gtk"),
    any(feature = "wx", target_os = "windows", target_os = "macos")
))]
fn platform_main() {
    let filter = if cfg!(debug_assertions) {
        "debug"
    } else {
        "warn"
    };
    init_logging(&[filter]);
    pdfinfo_wx::run();
}
