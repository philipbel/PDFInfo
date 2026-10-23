use font_locator::FontInfo;
use wxdragon::ffi::WXD_ID_PREFERENCES;
use wxdragon::prelude::*;


const MENU_ID_FILE_OPEN: i32 = 1001;
const MENU_ID_FILE_CLOSE: i32 = 1002;
const MENU_ID_FILE_QUIT: i32 = 1003;
const MENU_ID_EDIT_PREFERENCES: i32 = 1101;
const MENU_ID_VIEW_SIDEBAR: i32 = 1201;
const MENU_ID_HELP_ABOUT: i32 = 1301;


fn create_menu_bar() -> MenuBar {
    let file_menu = Menu::builder()
        .append_item(MENU_ID_FILE_OPEN, "&Open...\tCtrl+O", "Open a document")
        .append_item(MENU_ID_FILE_CLOSE, "&Close\tCtrl+W", "Close the document")
        .append_separator()
        .append_item(MENU_ID_FILE_QUIT, "&Quit\tCtrl+Q", "Quit PDF Info")
        .build();

    let edit_menu = Menu::builder()
        .append_item(
            MENU_ID_EDIT_PREFERENCES,
            "&Preferences\tCtrl+,",
            "Show preferences",
        )
        .build();

    let view_menu = Menu::builder()
        .append_check_item(MENU_ID_VIEW_SIDEBAR, "&Sidebar\tCtrl+I", "Sidebar")
        .build();

    let help_menu = Menu::builder()
        .append_item(
            MENU_ID_HELP_ABOUT,
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


pub fn run() {
    let _ = wxdragon::main(|_| {
        // TODO: Add to settings
        wxdragon::app::set_appearance(Appearance::System);

        let frame = Frame::builder()
            .with_title("PDF Info")
            .with_size(Size::new(800, 600))
            .build();

        let notebook = Notebook::builder(&frame)
            .with_style(NotebookStyle::Top | NotebookStyle::Default)
            .build();

        

        let splitter = SplitterWindow::builder(&notebook)
            .with_style(SplitterWindowStyle::LiveUpdate | SplitterWindowStyle::Default)
            .with_size(Size::new(200, 200))
            .build();
        let main_panel = Panel::builder(&splitter).build();
        let sidebar_panel = Panel::builder(&splitter)
            .with_style(PanelStyle::BorderTheme)
            .build();
        splitter.split_vertically(&main_panel, &sidebar_panel, 0);


        frame.set_menu_bar(create_menu_bar());
        frame.center_on_screen();
        frame.show(true);
    });
}
