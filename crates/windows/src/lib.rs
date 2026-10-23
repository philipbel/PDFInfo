use font_locator::FontInfo;
use windows_reactor::*;


struct MainWindow {}

impl MainWindow {
    fn list_view(&self) -> View {
        ListView::new()
            .can_reorder_items(false)
            .can_drag_items(false)
            .selection_mode(Some(ListViewSelectionMode::Single))
            .collection_slot(
                ListViewSlot::Items,
                (1u32..=5)
                    .map(|i| KeyedView::new(i, ListViewItem::new().content(format!("Item {i}")))),
            )
            .into()
    }

    fn split_view(&self) -> View {
        SplitView::new()
            .is_pane_open(true)
            .display_mode(SplitViewDisplayMode::Inline)
            .place
            .slots([
                SlotView::new(SplitViewSlot::Pane, "Pane"),
                SlotView::new(
                    SplitViewSlot::Content,
                    StackPanel::new()
                        .orientation(Some(Orientation::Vertical))
                        .spacing(0.0)
                        .children(["Content".into(), self.list_view()]),
                ),
            ])
            .into()
    }

    fn tab_view(&self) -> View {
        TabView::new()
            .selected_index(0)
            .is_add_tab_button_visible(true)
            .collection_slot(
                TabViewSlot::TabItems,
                vec![KeyedView::new(
                    "Tab 1".to_string(),
                    TabViewItem::new()
                        .header("Tab 1")
                        .content(self.split_view()),
                )],
            )
            .into()
    }
}

impl Component for MainWindow {
    type Input = ();
    type Message = ();

    fn create(_input: &(), _context: &ComponentContext<Self>) -> Self {
        Self {}
    }

    fn update(&mut self, _message: (), _context: &ComponentContext<Self>) {
    }

    fn view(&self, _input: &(), context: &mut ViewContext<Self>) -> View {
        context.window_title("PDF Info");
        context.window_visuals(WindowVisuals::new().backdrop(WindowBackdrop::Mica));

        // Button::new().content("Button").into()

        StackPanel::new()
            .spacing(8.0)
            .children((self.tab_view(),))
            .into()
    }
}

pub fn run() {
    App::run_component::<MainWindow>(()).unwrap();
}
