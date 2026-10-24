fn main() {
    println!("cargo:rerun-if-changed=build.rs");

    if cfg!(target_os = "windows") {
        let pkg_name = std::env::var("CARGO_PKG_NAME").unwrap();
        embed_manifest(&pkg_name);
    }
}

#[cfg(not(target_os = "windows"))]
fn embed_manifest(_name: &str) {
}

#[cfg(target_os = "windows")]
fn embed_manifest(name: &str) {
    use embed_manifest::manifest::SupportedOS::*;
    use embed_manifest::manifest::{
        ActiveCodePage,
        Setting,
    };
    use embed_manifest::{
        embed_manifest,
        new_manifest,
    };

    let manifest = new_manifest(name)
        .supported_os(Windows7..=Windows10)
        .active_code_page(ActiveCodePage::Utf8)
        // Enable heap type optimization for better performance (if available)
        .heap_type(embed_manifest::manifest::HeapType::SegmentHeap)
        .dpi_awareness(embed_manifest::manifest::DpiAwareness::PerMonitorV2)
        .long_path_aware(Setting::Enabled);
    if let Err(e) = embed_manifest(manifest) {
        println!("cargo:error=Failed to embed manifest: {e}");
    }
}
