// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT


use std::path::{
    Path,
    PathBuf,
};

use font_locator::FontInfo;
use log::debug;
use pdf_engine::{
    Font,
    FontSubtype,
};

thread_local! {
    static FT: freetype::Library = freetype::Library::init().expect("FreeType init");
}

#[derive(Debug)]
pub struct PreviewFontFaces {
    pub path: Option<PathBuf>,
    pub system_font_face: Option<cairo::FontFace>,
    pub embedded_font_face: Option<cairo::FontFace>,
}

impl PreviewFontFaces {
    pub fn load(pdf_font: &Font) -> Option<PreviewFontFaces> {
        if pdf_font.subtype() == FontSubtype::Type3 {
            return None;
        }

        let font_info = pdf_font
            .display_name()
            .and_then(FontInfo::find)
            .inspect(|fi| debug!("Found font {fi:?}"));
        let system_font_face = font_info
            .and_then(|fi| Self::load_font_from_path(fi.path, fi.postscript_name))
            .and_then(|f| cairo::FontFace::create_from_ft(&f).ok());
        let embedded_font_face = pdf_font
            .descriptor()
            .and_then(|d| d.program())
            .map(|p| p.data())
            .and_then(Self::load_font_from_memory)
            .map(|f| cairo::FontFace::create_from_ft(&f))
            .and_then(Result::ok);

        if system_font_face.is_none() && embedded_font_face.is_none() {
            None
        } else {
            Some(PreviewFontFaces {
                path: font_info.map(|fi| fi.path.into()),
                system_font_face,
                embedded_font_face,
            })
        }
    }

    fn load_font_from_path(path: &Path, postscript_name: &str) -> Option<freetype::Face> {
        FT.with(|lib| {
            let first_face = lib
                .new_face(path, 0)
                .inspect_err(|e| {
                    debug!(
                        "FreeType: new_face: {e} for path {}, postscript_name: {postscript_name}",
                        path.display()
                    )
                })
                .ok()?;

            if first_face.postscript_name().as_deref() == Some(postscript_name) {
                return Some(first_face);
            }
            // Loop over the TTC
            for i in 1..first_face.num_faces() as isize {
                let face = lib.new_face(path, i).ok();
                if let Some(face) = face
                    && face.postscript_name().as_deref() == Some(postscript_name)
                {
                    return Some(face);
                }
            }
            None
        })
    }

    fn load_font_from_memory(data: &[u8]) -> Option<freetype::Face> {
        FT.with(|lib| lib.new_memory_face(data.to_vec(), 0)).ok()
    }
}
