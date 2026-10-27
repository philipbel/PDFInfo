// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT


// This file implements Icon, a helper that manages bitmaps from SVG icon files.
//
// wxWidgets wxBitmapBundle::GetBitmap sets the scale factor of the bitmap to
// the default size in the bundle. When used with SVG, under the expectation
// that the BitmapBundle would hand out a scaled bitmap at the requested size,
// it doesn't work--the bundle instead hands out the bitmap at the requested
// size, but sets its scale factor so that it draws at its default size.

use std::cell::RefCell;
use std::collections::HashMap;
use std::num::NonZeroUsize;
use std::rc::Rc;

use log::warn;
use lru::LruCache;
use wxdragon::{
    ArtProvider,
    Bitmap,
    BitmapBundle,
    Colour,
    Size,
    SystemSettings,
};


#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum IconSize {
    Toolbar,
    Custom(i32, i32),
}


const NUM_CACHED_ICONS: usize = 10;


#[derive(Debug, Hash, Eq, PartialEq)]
struct IconCacheKey {
    width: i32,
    height: i32,
    fill_color: u32, // RGBA
}

struct IconCache {
    parsed_svg: Option<xmltree::Element>,
    cache: LruCache<IconCacheKey, Rc<BitmapBundle>>,
}


thread_local! {
    static CACHE_MAP: RefCell<HashMap<Icon, IconCache>> = RefCell::new(HashMap::new());
}


impl IconCache {
    fn get_or_update(&mut self, size: Size, fill_color: Option<Colour>) -> Rc<BitmapBundle> {
        // SystemSettings::get_colour handles dark mode automatically
        let fill_color = fill_color
            .unwrap_or_else(|| SystemSettings::get_colour(wxdragon::SystemColour::WindowText));
        let key = IconCacheKey {
            width: size.width,
            height: size.height,
            fill_color: fill_color.as_u32(),
        };
        if let Some(bundle) = self.cache.get(&key) {
            bundle.clone()
        } else {
            let bundle = Rc::new(
                recolored_svg_data(self.parsed_svg.as_ref(), fill_color)
                    .and_then(|data| BitmapBundle::from_svg_data(data.as_slice(), size))
                    .unwrap_or_default(),
            );
            _ = self.cache.put(key, bundle.clone());
            bundle
        }
    }
}


fn recolored_svg_data(svg: Option<&xmltree::Element>, fill_color: Colour) -> Option<Vec<u8>> {
    let svg = svg?;
    let mut tree = svg.clone();
    if let Some(path) = tree.get_mut_child("path")
        && let Some(fill) = path.attributes.get_mut("fill")
    {
        *fill = format!(
            "#{:02x}{:02x}{:02x}",
            fill_color.r, fill_color.g, fill_color.b
        );
    }
    let mut buffer = Vec::<u8>::default();
    tree.write(&mut buffer).ok()?;
    Some(buffer)
}


fn parse_svg(icon: Icon) -> Option<xmltree::Element> {
    xmltree::Element::parse(icon.svg())
        .inspect_err(|e| warn!("Cannot load SVG: {e}"))
        .ok()
}


impl Icon {
    fn get_bundle(self, size: Size, fill_color: Option<Colour>) -> Rc<BitmapBundle> {
        CACHE_MAP.with_borrow_mut(|m| {
            let cache = m.entry(self).or_insert_with(|| IconCache {
                parsed_svg: parse_svg(self),
                cache: LruCache::sparse(NonZeroUsize::new(NUM_CACHED_ICONS).unwrap()),
            });
            cache.get_or_update(size, fill_color)
        })
    }

    pub fn bundle(self, size: IconSize, fill_color: Option<Colour>) -> Rc<BitmapBundle> {
        let size = match size {
            IconSize::Toolbar => ArtProvider::get_dip_size_hint(wxdragon::ArtClient::Toolbar),
            IconSize::Custom(w, h) => Size {
                width: w,
                height: h,
            },
        };
        self.get_bundle(size, fill_color)
    }
}


macro_rules! icons {
    ($($variant:ident => $file:literal),* $(,)?) => {
        #[derive(Debug, Clone, Copy, Hash, PartialEq, Eq)]
        #[allow(clippy::enum_variant_names)]
        pub(crate) enum Icon { $($variant),* }

        impl Icon {
            pub(crate) fn svg(self) -> &'static [u8] {
                match self {
                    $(Icon::$variant => include_bytes!(concat!("../assets/icons/", $file))),*
                }
            }
        }
    };
}


icons! {
    DocumentAddFilled => "ic_fluent_document_add_48_filled.svg",
    DocumentAddRegular => "ic_fluent_document_add_48_regular.svg",
    DocumentPdfFilled => "ic_fluent_document_pdf_32_filled.svg",
    DocumentPdfRegular => "ic_fluent_document_pdf_32_regular.svg",
}
