// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::env;
use std::path::PathBuf;

pub fn project_root_dir() -> PathBuf {
    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
    manifest_dir.join("../..")
}

pub fn cmake_build_type() -> &'static str {
    match env::var("PROFILE").as_deref() {
        Ok("release") => "Release",
        _ => "Debug",
    }
}

pub fn is_debug_build() -> bool {
    env::var("DEBUG").unwrap() == "true"
}

pub fn cmake_osx_architecture() -> Option<&'static str> {
    match env::var("CARGO_CFG_TARGET_OS").unwrap().as_str() {
        "macos" => match env::var("CARGO_CFG_TARGET_ARCH").unwrap().as_str() {
            "aarch64" => Some("arm64"),
            "x86_64" => Some("x86_64"),
            other => panic!("unsupported macOS architecture: {other}"),
        },
        _ => None,
    }
}

pub fn append_pkg_config_path(dir: PathBuf) {
    let mut paths = Vec::default();
    if let Some(existing) = env::var_os("PKG_CONFIG_PATH") {
        paths.extend(env::split_paths(&existing))
    }
    paths.push(dir);
    // SAFETY: build script
    unsafe {
        env::set_var("PKG_CONFIG_PATH", env::join_paths(paths).unwrap());
    }
}
