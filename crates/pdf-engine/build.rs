// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

// cSpell: words statik

use std::env;
use std::path::PathBuf;

use common_build::{
    cmake_build_type,
    cmake_osx_architecture,
    is_debug_build,
};


const HEADER: &str = "include/pdf-engine/pdf-engine.h";

fn main() {
    let root_dir = PathBuf::from(env!("PROJECT_ROOT_DIR"));
    let src_dir = root_dir.join("libs/pdf-engine-core");
    let mut cmake_config = cmake::Config::new(&src_dir);
    if let Some(osx_architectures) = cmake_osx_architecture() {
        cmake_config.define("CMAKE_OSX_ARCHITECTURES", osx_architectures);
    }
    if let Ok(osx_deployment_target) = env::var("CMAKE_OSX_DEPLOYMENT_TARGET") {
        cmake_config.define("CMAKE_OSX_DEPLOYMENT_TARGET", osx_deployment_target);
    }
    let dst = cmake_config
        .profile(cmake_build_type())
        .very_verbose(is_debug_build())
        .build();

    unsafe {
        env::set_var("PKG_CONFIG_PATH", dst.join("lib/pkgconfig"));
    }
    pkg_config::Config::new()
        .statik(true)
        .probe("pdf-engine-core")
        .expect("could not find pkg-config for pdf-engine-core");

    println!("cargo::rerun-if-changed={}", src_dir.display());

    bindgen::Builder::default()
        .formatter(bindgen::Formatter::None)
        .header(src_dir.join(HEADER).into_string().unwrap())
        .allowlist_function("pdf_.*")
        .allowlist_type("pdf_.*")
        .prepend_enum_name(false)
        .rust_edition(bindgen::RustEdition::Edition2024)
        .generate()
        .expect("bindgen failed")
        .write_to_file(PathBuf::from(env::var("OUT_DIR").unwrap()).join("bindings.rs"))
        .unwrap();
}
