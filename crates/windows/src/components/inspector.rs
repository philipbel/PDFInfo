// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use windows_reactor::*;

use crate::components::random_color;


pub(super) struct InspectorComponent {}

impl InspectorComponent {
}

impl Component for InspectorComponent {
    type Input = ();
    type Message = ();

    fn create(input: &Self::Input, context: &ComponentContext<Self>) -> Self {
        Self {}
    }

    fn view(&self, input: &Self::Input, context: &mut ViewContext<Self>) -> View {
        Border::new()
            .content(TextBlock::new().text("Inspector"))
            .background(random_color())
            .into()
    }
}
