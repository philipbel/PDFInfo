// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use wxdragon::prelude::*;

use crate::Icon;
use crate::views::View;


pub(crate) struct IconView {
    panel: Panel,
}


impl IconView {
    /// Size is in DIPs
    pub(crate) fn new<P: WxWidget>(parent: &P, icon: Icon, size: Size) -> Self {
        let panel = Panel::builder(parent).build();
        panel.set_min_size(panel.from_dip(size));
        panel.set_background_style(BackgroundStyle::Paint);
        panel.on_paint(move |_| Self::paint(&panel, icon, size));
        _ = panel.bind_internal(EventType::SYS_COLOUR_CHANGED, move |event| {
            panel.refresh(true, None);
            event.skip(true);
        });

        Self { panel }
    }

    fn paint(panel: &Panel, icon: Icon, size: Size) {
        let dc = AutoBufferedPaintDC::new(panel);
        dc.set_background(panel.get_background_color());
        dc.clear();

        let bundle = icon.bundle(crate::icon::IconSize::Custom(size.width, size.height), None);
        let Some(bitmap) = bundle.get_bitmap_for(panel) else {
            return;
        };

        let logical_size = panel.from_dip(size);
        let client_size = panel.get_client_size();
        dc.draw_bitmap(
            &bitmap,
            (client_size.width - logical_size.width) / 2,
            (client_size.height - logical_size.height) / 2,
            true,
        );
    }
}


impl View for IconView {
    type Root = Panel;

    fn root_view(&self) -> Self::Root {
        self.panel
    }
}
