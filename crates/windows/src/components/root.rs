// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT


use std::fs;
use std::path::PathBuf;

use log::debug;
use pdf_engine::Document;
use windows_pickers::OpenFilePicker;
use windows_reactor::*;
use windows_result::Result;

use crate::components::document::{
    DocumentComponent,
    DocumentComponentInput,
};
use crate::components::inspector::InspectorComponent;
use crate::components::random_color;
use crate::models::DocumentModel;


const FILE_OPEN_MENU_ITEM_KEY: &str = "file-open";
const FILE_CLOSE_MENU_ITEM_KEY: &str = "file-close";


pub(crate) struct RootComponent {
    documents: Vec<DocumentModel>,
    selected_document_index: Option<usize>,
}

#[derive(Clone)]
pub(crate) enum RootComponentMessage {
    MenuItemClicked(Key),
    FilesPicked(Result<Vec<PathBuf>>),
    SelectedDocumentTabChanged(Option<usize>),
}

impl RootComponent {
    fn tab_view(&self, context: &ViewContext<Self>) -> TabView {
        let tabs = self.documents.iter().map(|d| {
            keyed(
                d.file.to_string_lossy().as_ref(),
                TabViewItem::new()
                    .header(&d.title)
                    .content(component::<DocumentComponent>(
                        format!("{}-document-component", d.file.display()),
                        DocumentComponentInput {
                            document: d.clone(),
                        },
                    )),
            )
        });
        TabView::new()
            .selected_index(self.selected_document_index)
            .on_selection_changed(
                context.callback(RootComponentMessage::SelectedDocumentTabChanged),
            )
            .is_add_tab_button_visible(true)
            .vertical_alignment(VerticalAlignment::Stretch)
            .keyed_tab_items(tabs)
    }

    fn menu_bar(&self, context: &mut ViewContext<Self>) -> Grid {
        let file_menu = Menu::new(
            [
                MenuItem::item(FILE_OPEN_MENU_ITEM_KEY, "Open"),
                MenuItem::item(FILE_CLOSE_MENU_ITEM_KEY, "Close"),
            ],
            context.callback(RootComponentMessage::MenuItemClicked),
        );
        let file_menu_bar_item = MenuBarItem::new().title("File").menu(file_menu);
        let menu = MenuBar::new().items([
            file_menu_bar_item,
            MenuBarItem::new().title("Edit").menu(Menu::new(
                [MenuItem::item("copy", "Copy")],
                |key| {}, // context.callback(Message::Menu),
            )),
        ]);
        let commands = CommandBar::new()
            .default_label_position(CommandBarDefaultLabelPosition::Collapsed)
            // .closed_display_mode(AppBarClosedDisplayMode::Minimal)
            // .overflow_button_visibility(CommandBarOverflowButtonVisibility::Collapsed)
        .primary_commands(
            (
                // TODO: Change icon based on state
                AppBarButton::new().label("Save").icon(Symbol::OpenPane)
                // .on_click(context.message(Message::Command))
                ,
            ),
        );
        Grid::new()
            .columns([GridLength::Auto, GridLength::STAR])
            .row_spacing(0.0)
            .children((menu, commands.grid_column(1)))
    }

    fn status_bar(&self, _context: &mut ViewContext<Self>) -> Grid {
        Grid::new()
            .columns([GridLength::STAR, GridLength::Auto])
            .children((
                TextBlock::new().text("Left").grid_column(0),
                TextBlock::new().text("Right").grid_column(1),
            ))
    }
}

impl Component for RootComponent {
    type Input = ();
    type Message = RootComponentMessage;

    fn create(_input: &(), _context: &ComponentContext<Self>) -> Self {
        Self {
            documents: Vec::new(),
            selected_document_index: None,
        }
    }

    fn update(&mut self, message: RootComponentMessage, context: &ComponentContext<Self>) {
        match message {
            RootComponentMessage::MenuItemClicked(key) => match key.as_str() {
                Some(FILE_OPEN_MENU_ITEM_KEY) => {
                    debug!("Showing file picker");
                    let picker = OpenFilePicker::new()
                        .title("Open PDF Files") // TODO: Translate
                        .commit_label("Open") // TODO: Translate
                        .default_location(windows_pickers::PickerLocation::Documents)
                        // TODO: Translate
                        .filter_extensions("Portable Document Format (PDF) Files", ["pdf"]);
                    _ = picker.request_multiple(context, RootComponentMessage::FilesPicked);
                }
                Some(FILE_CLOSE_MENU_ITEM_KEY) => {} // TODO: Implement
                Some(_) => {}
                None => {}
            },
            RootComponentMessage::FilesPicked(result) => {
                // TODO: Handle errors
                match result {
                    Ok(paths) => {
                        for path in &paths {
                            let content = fs::read(path).unwrap();
                            let document = Document::open(&content).unwrap();
                            self.documents.push(DocumentModel::new(path, document));
                        }
                        // Select the last document
                        self.selected_document_index = if !self.documents.is_empty() {
                            Some(self.documents.len() - 1)
                        } else {
                            None
                        }
                    }
                    Err(err) => {
                        panic!("error: {err}");
                    }
                }
            }
            RootComponentMessage::SelectedDocumentTabChanged(index) => {
                self.selected_document_index = index
            }
        }
    }

    fn view(&self, _input: &(), context: &mut ViewContext<Self>) -> View {
        context.window_title("PDF Info"); // TODO: Translate
        context.window_visuals(WindowVisuals::new().backdrop(WindowBackdrop::MicaAlt));
        // TODO: Icon?
        // TODO: Drag and drop

        let content: View = if self.selected_document_index.is_some() {
            self.tab_view(context).into()
        } else {
            TextBlock::new().text("TODO: No Document").into()
        };

        let content_container = Border::new()
            // .background(ThemeBrush::CardBackground)
            .content(content);

        Grid::new()
            .rows([GridLength::Auto, GridLength::STAR, GridLength::Auto])
            .children([
                self.menu_bar(context).into(),
                content_container.grid_row(1).into(),
                self.status_bar(context).grid_row(2).into(),
            ])
            .into()
    }
}
