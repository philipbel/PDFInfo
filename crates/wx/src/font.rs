// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use wxdragon::{
    Font,
    FontFamily,
    FontWeight,
};


struct SystemFontStyle(i32, FontWeight);


// Based on https://learn.microsoft.com/en-us/windows/apps/design/signature-experiences/typography
const CAPTION_SYSTEM_FONT_STYLE: SystemFontStyle = SystemFontStyle(12, FontWeight::Light);
const BODY_SYSTEM_FONT_STYLE: SystemFontStyle = SystemFontStyle(14, FontWeight::Normal);
const BODY_STRONG_SYSTEM_FONT_STYLE: SystemFontStyle = SystemFontStyle(14, FontWeight::SemiBold);
const BODY_LARGE_SYSTEM_FONT_STYLE: SystemFontStyle = SystemFontStyle(18, FontWeight::Normal);
const BODY_LARGE_STRONG_SYSTEM_FONT_STYLE: SystemFontStyle =
    SystemFontStyle(18, FontWeight::SemiBold);
const SUBTITLE_SYSTEM_FONT_STYLE: SystemFontStyle = SystemFontStyle(20, FontWeight::SemiBold);
const TITLE_SYSTEM_FONT_STYLE: SystemFontStyle = SystemFontStyle(28, FontWeight::SemiBold);
const TITLE_LARGE_SYSTEM_FONT_STYLE: SystemFontStyle = SystemFontStyle(40, FontWeight::SemiBold);
const DISPLAY_SYSTEM_FONT_STYLE: SystemFontStyle = SystemFontStyle(79, FontWeight::SemiBold);

fn make_font(style: &SystemFontStyle) -> Font {
    Font::builder()
        .with_family(wxdragon::FontFamily::Default)
        .with_point_size(style.0)
        .with_weight(style.1)
        .build()
        .unwrap_or_default()
}

pub(crate) trait FontExt {
    fn caption() -> Font {
        make_font(&CAPTION_SYSTEM_FONT_STYLE)
    }

    fn body() -> Font {
        make_font(&BODY_SYSTEM_FONT_STYLE)
    }

    fn body_strong() -> Font {
        make_font(&BODY_STRONG_SYSTEM_FONT_STYLE)
    }

    fn body_large() -> Font {
        make_font(&BODY_LARGE_SYSTEM_FONT_STYLE)
    }

    fn body_large_strong() -> Font {
        make_font(&BODY_LARGE_STRONG_SYSTEM_FONT_STYLE)
    }

    fn subtitle() -> Font {
        make_font(&SUBTITLE_SYSTEM_FONT_STYLE)
    }

    fn title() -> Font {
        make_font(&TITLE_SYSTEM_FONT_STYLE)
    }

    fn title_large() -> Font {
        make_font(&TITLE_LARGE_SYSTEM_FONT_STYLE)
    }

    fn display() -> Font {
        make_font(&DISPLAY_SYSTEM_FONT_STYLE)
    }
}


impl FontExt for Font {
}
