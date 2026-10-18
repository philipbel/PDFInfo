// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::env;
use std::path::PathBuf;

use common_build::{
    extract_compile_commands,
    is_debug_build,
    project_root_dir,
    target_os,
};

fn main() {
    let root_dir = project_root_dir();
    let core_dir = root_dir.join("font-locator/core");
    let dst = cmake::Config::new(&core_dir)
        .very_verbose(is_debug_build())
        .profile(build_type())
        .build();

    extract_compile_commands(env!("CARGO_PKG_NAME"), &dst.join("build"));

    println!("cargo::rerun-if-changed={}", core_dir.display());

    println!(
        "cargo::rustc-link-search=native={}",
        dst.join("lib").display()
    );
    println!("cargo::rustc-link-lib=static=font-locator-core");

    match target_os().as_str() {
        "macos" => {
            println!("cargo::rustc-link-lib=c++");
            println!("cargo::rustc-link-lib=framework=CoreFoundation");
            println!("cargo::rustc-link-lib=framework=CoreText");
        }
        "linux" => {
            _ = pkg_config::probe_library("fontconfig").unwrap();
            println!("cargo::rustc-link-lib=stdc++");
        }
        _ => {}
    }

    bindgen::Builder::default()
        .formatter(bindgen::Formatter::None)
        .header(
            core_dir
                .join("include/font-locator/font-locator.h")
                .to_str()
                .unwrap(),
        )
        .allowlist_function("font_locator_.*")
        .allowlist_type("font_locator_.*")
        .prepend_enum_name(false)
        .rust_edition(bindgen::RustEdition::Edition2024)
        .generate()
        .expect("bindgen failed")
        .write_to_file(PathBuf::from(env::var("OUT_DIR").unwrap()).join("bindings.rs"))
        .unwrap();
}

fn build_type() -> &'static str {
    match std::env::var("PROFILE").as_deref() {
        Ok("release") => "Release",
        _ => "Debug",
    }
}
