// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::{fs, path::Path};

use pdf_engine::Document;

pub fn load_file(name: &str) -> Vec<u8> {
    let path = Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("../../etc/test-pdfs")
        .join(format!("{name}.pdf"));
    fs::read(&path).unwrap_or_else(|e| panic!("failed to open file {}: {e}", path.display()))
}

pub fn load_document(name: &str) -> Document {
    let bytes = load_file(name);
    Document::open(bytes.as_slice()).unwrap()
}
