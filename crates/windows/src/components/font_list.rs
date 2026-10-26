// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::rc::Rc;

use log::debug;
use pdf_engine::FontId;
use windows_reactor::*;

use crate::components::random_color;
use crate::models::FontModel;


#[derive(Debug, Clone, PartialEq)]
pub(super) struct FontListInput {
    pub(super) fonts: Rc<Vec<FontModel>>,
    pub(super) selected_font_id: Option<FontId>,
    pub(super) on_font_selected: Callback<Option<FontId>>,
}


pub(super) struct FontListComponent {}

impl Component for FontListComponent {
    type Input = FontListInput;
    type Message = ();

    fn create(_input: &Self::Input, _context: &ComponentContext<Self>) -> Self {
        Self {}
    }

    fn view(&self, input: &Self::Input, _context: &mut ViewContext<Self>) -> View {
        let fonts = input.fonts.clone();
        let on_font_selected = input.on_font_selected.clone();

        // TODO: Adjust when sorting is added
        let selected_index = if let Some(id) = input.selected_font_id {
            input.fonts.iter().position(|f| f.id == id)
        } else {
            None
        };
        ListView::new()
            .can_reorder_items(false)
            .can_drag_items(false)
            .selection_mode(ListViewSelectionMode::Single)
            .items(input.fonts.iter().map(Self::font_item))
            .selected_index(selected_index)
            .on_selection_changed(move |index: Option<usize>| {
                let font_id = index.and_then(|i| fonts.get(i)).map(|f| f.id);
                debug!("Selected font index {index:?}, id {font_id:?}");
                on_font_selected.call(font_id);
            })
            .into()
    }
}

impl FontListComponent {
    fn font_item(font: &FontModel) -> DataItem {
        DataItem::new(font.id, format!("Font {}", font.id)).content(
            Border::new()
                .background(random_color())
                .content(TextBlock::new().text(&font.display_name)),
        )
    }
}
