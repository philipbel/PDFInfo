// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::env;
use std::path::PathBuf;

use common_build::{
    cmake_build_type,
    extract_compile_commands,
    is_debug_build,
    project_root_dir,
    target_os,
    target_prefix_dir,
};

fn main() {
    let root_dir = project_root_dir();
    let core_dir = root_dir.join("pdf-engine/core");
    let target_prefix_dir = target_prefix_dir();
    let target_lib_dir = target_prefix_dir.join("lib");
    let dst = cmake::Config::new(&core_dir)
        .profile(cmake_build_type())
        .very_verbose(is_debug_build())
        .define("CMAKE_PREFIX_PATH", &target_prefix_dir)
        .build();

    extract_compile_commands(env!("CARGO_PKG_NAME"), &dst.join("build"));

    println!("cargo::rerun-if-changed={}", core_dir.display());
    println!("cargo::rerun-if-changed={}", target_lib_dir.display());

    println!(
        "cargo::rustc-link-search=native={}",
        dst.join("lib").display()
    );
    println!(
        "cargo::rustc-link-search=native={}",
        target_lib_dir.display()
    );

    // Order matters
    println!("cargo::rustc-link-lib=static=pdf-engine-core");
    println!("cargo::rustc-link-lib=static=qpdf");
    println!("cargo::rustc-link-lib=static=jpeg");
    println!("cargo::rustc-link-lib=static=z");

    match target_os().as_str() {
        "macos" => println!("cargo::rustc-link-lib=c++"),
        "linux" => println!("cargo::rustc-link-lib=stdc++"),
        _ => {}
    }

    bindgen::Builder::default()
        .formatter(bindgen::Formatter::None)
        .header(
            core_dir
                .join("include/pdf-engine/pdf-engine.h")
                .to_str()
                .unwrap(),
        )
        .allowlist_function("pdf_.*")
        .allowlist_type("pdf_.*")
        .prepend_enum_name(false)
        .rust_edition(bindgen::RustEdition::Edition2024)
        .generate()
        .expect("bindgen failed")
        .write_to_file(PathBuf::from(env::var("OUT_DIR").unwrap()).join("bindings.rs"))
        .unwrap();
}
