// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use wxdragon::prelude::*;

use crate::font::FontExt as _;
use crate::views::View;


pub(crate) struct NoContentView {
    panel: Panel,
}

impl NoContentView {
    pub(crate) fn new<P: WxWidget>(
        title: impl AsRef<str>,
        description: impl AsRef<str>,
        parent: &P,
    ) -> Self {
        let panel = Panel::builder(parent).build();

        let sizer = BoxSizer::builder(Orientation::Vertical).build();
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

impl View for NoContentView {
    type Root = Panel;

    fn root_view(&self) -> Self::Root {
        self.panel
    }
}
