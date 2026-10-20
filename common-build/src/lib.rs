// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::env;
use std::fs::{
    create_dir_all,
    remove_file,
};
use std::os::unix;
use std::path::{
    Path,
    PathBuf,
};


pub const COMPILE_COMMANDS_FILENAME: &str = "compile_commands.json";


pub fn target_arch() -> String {
    match env::var("CARGO_CFG_TARGET_ARCH").unwrap().as_str() {
        "aarch64" => "arm64".to_string(),
        "x86_64" => "x86_64".to_string(),
        other => panic!("unsupported architecture: {other}"),
    }
}

pub fn target_os() -> String {
    env::var("CARGO_CFG_TARGET_OS").unwrap()
}


pub fn project_root_dir() -> PathBuf {
    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
    manifest_dir.join("../..")
}


pub fn extract_compile_commands(package_name: &str, src_dir: &Path) {
    // This is hacky...
    // CMake generates its compile_commands.json file in OUT_DIR/<project-hash>/out/build/
    // OUT_DIR is passed in by cargo.

    let dst_dir = &project_prefix_dir().join(env!("COMPILE_COMMANDS_DIRNAME"));
    if !dst_dir.exists() {
        create_dir_all(dst_dir).expect("failed to create destination dir");
    }

    let src_file = src_dir.join(COMPILE_COMMANDS_FILENAME);
    // Ignore whether the file exists or not
    let dst_file = dst_dir.join(format!("{package_name}-{COMPILE_COMMANDS_FILENAME}"));
    if dst_file.exists() {
        remove_file(&dst_file).expect("failed to remove file");
    }

    if cfg!(windows) {
    } else {
        unix::fs::symlink(&src_file, &dst_file).expect("failed to create symlink");
    }
    println!("Symlinked {} -> {}", src_file.display(), dst_file.display());
}


pub fn cmake_build_type() -> &'static str {
    match env::var("PROFILE").as_deref() {
        Ok("release") => "Release",
        _ => "Debug",
    }
}


pub fn project_prefix_dir() -> PathBuf {
    let root_dir = project_root_dir();
    root_dir.join(env!("PREFIX_DIR"))
}


pub fn target_os_prefix_dir() -> PathBuf {
    project_prefix_dir().join(target_os())
}

pub fn target_prefix_dir() -> PathBuf {
    target_os_prefix_dir().join(target_arch())
}


pub fn is_debug_build() -> bool {
    env::var("DEBUG").unwrap() == "true"
}
