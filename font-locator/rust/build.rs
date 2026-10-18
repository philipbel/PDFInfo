// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::env;
use std::path::PathBuf;

fn main() {
    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());

    let root_dir = manifest_dir.join("../..");

    let core_dir = root_dir.join("font-locator/core");

    let target_os = env::var("CARGO_CFG_TARGET_OS").unwrap();

    let dst = cmake::Config::new(&core_dir).profile(build_type()).build();

    println!("cargo::rerun-if-changed={}", core_dir.display());

    println!(
        "cargo::rustc-link-search=native={}",
        dst.join("lib").display()
    );

    println!("cargo::rustc-link-lib=static=font-locator-core");

    match target_os.as_str() {
        "macos" => {
            println!("cargo::rustc-link-lib=c++");
            println!("cargo::rustc-link-lib=framework=CoreFoundation");
            println!("cargo::rustc-link-lib=framework=CoreText");
        }
        "linux" => println!("cargo::rustc-link-lib=stdc++"),
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
