// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT


use pdf_engine::FontId;
use windows_reactor::*;

use crate::components::font_list::{
    FontListComponent,
    FontListInput,
};
use crate::components::inspector::InspectorComponent;
use crate::models::DocumentModel;


#[derive(Debug, Clone, PartialEq)]
pub(super) struct DocumentComponentInput {
    pub(super) document: DocumentModel,
}


#[derive(Debug, Clone, PartialEq)]
pub(super) enum DocumentComponentMessage {
    SelectedFontChanged(Option<FontId>),
}


pub(super) struct DocumentComponent {
    selected_font_id: Option<FontId>,
}


impl Component for DocumentComponent {
    type Input = DocumentComponentInput;
    type Message = DocumentComponentMessage;

    fn create(_input: &Self::Input, _context: &ComponentContext<Self>) -> Self {
        Self {
            selected_font_id: None,
        }
    }

    fn update(&mut self, message: Self::Message, _context: &ComponentContext<Self>) {
        match message {
            DocumentComponentMessage::SelectedFontChanged(font_id) => {
                self.selected_font_id = font_id
            }
        }
    }

    fn view(&self, input: &Self::Input, context: &mut ViewContext<Self>) -> View {
        SplitView::new()
            .is_pane_open(true)
            .display_mode(SplitViewDisplayMode::Inline)
            .pane_placement(SplitViewPanePlacement::Right)
            .pane(component::<InspectorComponent>("inspector", ()))
            .content(component::<FontListComponent>(
                "font-list",
                FontListInput {
                    fonts: input.document.fonts.clone(),
                    selected_font_id: self.selected_font_id,
                    on_font_selected: context
                        .callback(DocumentComponentMessage::SelectedFontChanged),
                },
            ))
            // .vertical_alignment(VerticalAlignment::Stretch)
            .into()
    }
}
