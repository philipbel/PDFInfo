use std::env;
use std::path::PathBuf;

fn main() {

    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());

    let root_dir = manifest_dir.join("../..");

    let core_dir = root_dir.join("pdf-engine/core");

    let target_os = env::var("CARGO_CFG_TARGET_OS").unwrap();

    let target_arch = match env::var("CARGO_CFG_TARGET_ARCH").unwrap().as_str() {
        "aarch64" => "arm64",
        "x86_64" => "x86_64",
        other => panic!("unsupported architecture: {other}"),
    };

    let prefix_dir = root_dir.join("build/prefix")
                             .join(&target_os)
                             .join(target_arch);

    let dst = cmake::Config::new(&core_dir).profile(build_type())
                                           .define("CMAKE_PREFIX_PATH", &prefix_dir)
                                           .build();

    println!("cargo::rerun-if-changed={}", core_dir.display());

    println!("cargo::rerun-if-changed={}",
             prefix_dir.join("lib").display());

    println!("cargo::rustc-link-search=native={}",
             dst.join("lib").display());

    println!("cargo::rustc-link-search=native={}",
             prefix_dir.join("lib").display());

    // Order matters
    println!("cargo::rustc-link-lib=static=pdf-engine-core");

    println!("cargo::rustc-link-lib=static=qpdf");

    println!("cargo::rustc-link-lib=static=jpeg");

    println!("cargo::rustc-link-lib=static=z");

    match target_os.as_str() {
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

fn build_type() -> &'static str {

    match std::env::var("PROFILE").as_deref() {
        Ok("release") => "Release",
        _ => "Debug",
    }
}
