// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use wxdragon::prelude::*;
use wxdragon::widgets::GenericStaticBitmap;

use crate::Icon;
use crate::font::FontExt as _;
use crate::views::View;
use crate::views::icon_view::IconView;


pub(crate) struct PlaceholderView {
    panel: Panel,
}

impl PlaceholderView {
    pub(crate) fn new<P: WxWidget>(
        title: impl AsRef<str>,
        description: impl AsRef<str>,
        icon: Icon,
        parent: &P,
    ) -> Self {
        let panel = Panel::builder(parent).build();

        let sizer = BoxSizer::builder(Orientation::Vertical).build();
        let icon_view = IconView::new(
            &panel,
            Icon::DocumentPdfRegular,
            Size {
                width: 128,
                height: 128,
            },
        );
        let title_text = StaticText::builder(&panel)
            .with_label(title.as_ref())
            .with_style(StaticTextStyle::AlignCenterHorizontal)
            .build();
        title_text.set_font(&Font::title());
        let description_text = StaticText::builder(&panel)
            .with_label(description.as_ref())
            .with_style(StaticTextStyle::AlignCenterHorizontal)
            .build();
        description_text.set_font(&Font::body_large());
        sizer.add_stretch_spacer(1);
        sizer.add(
            &icon_view.root_view(),
            0,
            SizerFlag::AlignCenterHorizontal,
            0,
        );
        sizer.add_spacer(16);
        sizer.add(
            &title_text,
            0,
            SizerFlag::FixedMinsize | SizerFlag::Expand,
            0,
        );
        sizer.add_spacer(8);
        sizer.add(
            &description_text,
            0,
            SizerFlag::FixedMinsize | SizerFlag::Expand,
            0,
        );
        sizer.add_stretch_spacer(1);
        panel.set_sizer_and_fit(sizer, true);

        Self { panel }
    }
}

impl View for PlaceholderView {
    type Root = Panel;

    fn root_view(&self) -> Self::Root {
        self.panel
    }
}
