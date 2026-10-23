use std::env;
use std::path::PathBuf;
use std::process::Command;

fn main() {
    let schema_out_dir = PathBuf::from(env::var("OUT_DIR").unwrap()).join("schemas");
    std::fs::create_dir_all(&schema_out_dir).unwrap();

    let status = Command::new("glib-compile-schemas")
        .arg("--strict")
        .arg("--targetdir")
        .arg(&schema_out_dir)
        .arg("data")
        .status()
        .expect("failed to run glib-compile-schemas");
    assert!(status.success(), "glib-compile-schemas failed");

    println!("cargo::rerun-if-changed=data");
    println!(
        "cargo::rustc-env=PDFINFO_SCHEMA_DIR={}",
        schema_out_dir.display()
    );

    glib_build_tools::compile_resources(
        &["data/resources"],
        "data/resources/resources.gresource.xml",
        "pdfinfo.gresource",
    );
}
