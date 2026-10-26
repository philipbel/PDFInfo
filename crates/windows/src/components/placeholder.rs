// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use windows_reactor::{
    Component,
    StackPanel,
};


pub(super) struct PlaceholderComponent {}

impl Component for PlaceholderComponent {
    type Input = ();
    type Message = ();

    fn create(input: &Self::Input, context: &windows_reactor::ComponentContext<Self>) -> Self {
        Self {}
    }

    fn view(
        &self,
        input: &Self::Input,
        context: &mut windows_reactor::ViewContext<Self>,
    ) -> windows_reactor::View {
        StackPanel::new()
            .children(["Drag PDF files here to inspect".into()])
            .into()
    }
}
