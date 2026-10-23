// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT


#![cfg_attr(target_os = "windows", windows_subsystem = "windows")]

// Linux and/or GTK
#[cfg(any(target_os = "linux", feature = "gtk"))]
fn main() {
    pdfinfo_gtk::run();
}

// Windows, native UI
#[cfg(all(target_os = "windows", not(feature = "gtk")))]
fn main() {
    pdfinfo_windows::run();
}
