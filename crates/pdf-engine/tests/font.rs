// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use pdf_engine::{
    FontDisplayType,
    FontSubtype,
    ProgramKind,
};

mod common;

#[test]
fn truetype_is_embedded() {
    let doc = common::load_document("simple_truetype");
    let font = &doc.fonts()[0];
    assert!(font.is_embedded());
    let program = font.descriptor().unwrap().program().unwrap();
    assert_eq!(program.kind(), ProgramKind::TrueType);
    assert!(!program.data().is_empty());
}

#[test]
fn display_types() {
    let doc = common::load_document("multi_font_mixed");
    let fonts = doc.fonts();
    assert_eq!(fonts.len(), 3);
    // cSpell: disable
    for f in fonts {
        if f.base_font().unwrap() == "Helvetica" {
            assert_eq!(f.subtype(), FontSubtype::Type1);
            assert_eq!(f.display_name().unwrap(), "Helvetica");
            assert_eq!(f.display_type(), FontDisplayType::Type1);
            assert!(!f.is_embedded());
            assert!(!f.is_subset());
            assert!(f.descriptor().is_none());
        } else if f.base_font().unwrap() == "YKZTXJ+IBM Plex Sans Regular" {
            assert_eq!(f.subtype(), FontSubtype::Type0);
            assert_eq!(f.display_type(), FontDisplayType::CidTrueType);
            assert_eq!(f.display_name().unwrap(), "IBM Plex Sans Regular");
            assert!(f.is_embedded());
            assert!(f.is_subset());
            assert!(f.descriptor().is_some());
            assert!(f.descriptor().unwrap().program().is_some());
            assert!(f.descriptor().unwrap().program().unwrap().kind() == ProgramKind::TrueType);
        } else if f.base_font().unwrap() == "LURHNR+IBM Plex Sans Regular" {
            assert_eq!(f.subtype(), FontSubtype::Type0);
            assert_eq!(f.display_type(), FontDisplayType::CidType0cOpenType);
            assert_eq!(f.display_name().unwrap(), "IBM Plex Sans Regular");
            assert!(f.is_embedded());
            assert!(f.is_subset());
            assert!(f.descriptor().is_some());
            assert!(f.descriptor().unwrap().program().is_some());
            assert!(f.descriptor().unwrap().program().unwrap().kind() == ProgramKind::OpenType);
        } else {
            panic!("Unexpected font found: {f:?}");
        }
    }
    // cSpell: enable
}
