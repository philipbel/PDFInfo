// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::cell::RefCell;
use std::path::Path;
use std::rc::Rc;
use std::sync::Arc;

use log::{
    debug,
    warn,
};
use wxdragon as wx;
use wxdragon::ffi::{
    WXD_ID_ABOUT,
    WXD_ID_CLOSE,
    WXD_ID_EXIT,
    WXD_ID_OPEN,
    WXD_ID_PREFERENCES,
};
use wxdragon::prelude::*;

use crate::Icon;
use crate::views::MainView;

const FILE_OPEN_ID: i32 = WXD_ID_OPEN as i32;
const FILE_CLOSE_ID: i32 = WXD_ID_CLOSE as i32;
const QUIT_ID: i32 = WXD_ID_EXIT as i32;
const PREFERENCES_ID: i32 = WXD_ID_PREFERENCES as i32;
const ABOUT_ID: i32 = WXD_ID_ABOUT as i32;
const VIEW_SIDEBAR_ID: i32 = 1_000;


pub(crate) struct App {
    frame: Frame,
    main_view: Rc<MainView>,
    tool_bar: Rc<RefCell<Option<ToolBar>>>,
    tool_bar_rebuild_timer: Rc<Timer<Frame>>,
}

impl App {
    pub(crate) fn new() -> Self {
        let frame = Frame::builder()
            .with_title("PDF Info")
            .with_size(Size::new(800, 600))
            .build();
        let main_view = MainView::new(&frame);
        let tool_bar = Rc::new(RefCell::new(Self::create_tool_bar(&frame)));

        let tool_bar_rebuild_timer = Rc::new(Timer::new(&frame));
        {
            let tool_bar = tool_bar.clone();
            tool_bar_rebuild_timer.on_tick(move |e| {
                // XXX: Restore the frame size. Otherwise, the frame keeps growing by the toolbar's
                // height
                let frame_size = frame.get_size();
                _ = tool_bar.replace(Self::create_tool_bar(&frame));
                frame.set_size(frame_size);
                e.skip(true);
            });
        }

        Self {
            frame,
            main_view: Rc::new(main_view),
            tool_bar,
            tool_bar_rebuild_timer,
        }
    }

    pub(crate) fn run(&self) {
        // TODO: Add to settings
        if !cfg!(target_os = "macos") {
            // XXX: On macOS, this pins the UI to the system appearance at the time of the call
            set_appearance(Appearance::System);
        }

        let frame = self.frame;
        let main_view = self.main_view.clone();
        self.frame.on_menu(move |event| match event.get_id() {
            FILE_OPEN_ID => {
                Self::on_file_open(&frame, &main_view);
            }
            _ => {
                warn!("Action for menu item {event:?} not implemented");
            }
        });
        // XXX: Recreate the toolbar every time the system appearance changes. wxDragon doesn't
        // provide wxToolbar's `SetToolNormalBitmap` method.
        {
            let tool_bar = self.tool_bar.clone();
            let timer = self.tool_bar_rebuild_timer.clone();
            _ = self
                .frame
                .bind_internal(EventType::SYS_COLOUR_CHANGED, move |e| {
                    tool_bar.borrow().as_ref().map(ToolBar::destroy);
                    // The toolbar is not destroyed immediately, so replacing it on the frame
                    // triggers an assert in wxWidgets/src/common/framecmn. cpp(657): assert
                    // "!m_frameToolBar" failed in CreateToolBar(): recreating toolbar in wxFrame
                    _ = timer.start(100, true);
                    e.skip(true);
                });
        }
        self.frame.set_menu_bar(self.create_menu_bar());
        self.frame.center_on_screen();
        self.frame.show(true);
    }

    fn create_tool_bar(frame: &Frame) -> Option<ToolBar> {
        let Some(tool_bar) =
            frame.create_tool_bar(Some(ToolBarStyle::Default | ToolBarStyle::Flat), -1)
        else {
            warn!("Failed to create tool bar");
            return None;
        };

        // TODO: Translate
        _ = tool_bar.add_tool_bundle(
            FILE_OPEN_ID,
            "Open",
            &Icon::DocumentAddRegular.bundle(crate::icon::IconSize::Toolbar, None),
            "Open a PDF document",
        );
        _ = tool_bar.realize();
        Some(tool_bar)
    }

    fn create_menu_bar(&self) -> MenuBar {
        let file_menu = Menu::builder()
            .append_item(FILE_OPEN_ID, "&Open...\tCtrl+O", "Open a document")
            .append_item(FILE_CLOSE_ID, "&Close\tCtrl+W", "Close the document")
            .append_separator()
            .append_item(QUIT_ID, "&Quit\tCtrl+Q", "Quit PDF Info")
            .build();

        let edit_menu = Menu::builder()
            .append_item(PREFERENCES_ID, "&Preferences\tCtrl+,", "Show preferences")
            .build();

        let view_menu = Menu::builder()
            .append_check_item(VIEW_SIDEBAR_ID, "&Sidebar\tCtrl+I", "Sidebar")
            .build();

        let help_menu = Menu::builder()
            .append_item(
                ABOUT_ID,
                "&About PDF Info",
                "Show information about PDF Info",
            )
            .build();

        MenuBar::builder()
            .append(file_menu, "&File")
            .append(edit_menu, "&Edit")
            .append(view_menu, "&View")
            .append(help_menu, "&Help")
            .build()
    }

    fn on_file_open<P: WxWidget>(parent: &P, main_view: &MainView) {
        let dialog = FileDialog::builder(parent)
            .with_message("Select one or more PDF files")
            .with_style(
                FileDialogStyle::Open | FileDialogStyle::Multiple | FileDialogStyle::FileMustExist,
            )
            .with_wildcard("Portable Document Format Files (*.pdf)|*.pdf")
            .build();
        if dialog.show_modal() == wx::ID_OK {
            let paths = dialog.get_paths();
            for p in paths {
                main_view.open_document(Path::new(&p));
            }
        };
    }
}
