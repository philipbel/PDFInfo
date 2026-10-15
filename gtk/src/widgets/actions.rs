use const_format::concatcp;

const WIN_PREFIX: &str = "win.";
const APP_PREFIX: &str = "app.";

#[cfg(target_os = "macos")]
const PRIMARY: &str = "<Meta>";
#[cfg(not(target_os = "macos"))]
const PRIMARY: &str = "<Control>";

pub const OPEN: &str = "open";
pub const WIN_OPEN: &str = concatcp!(WIN_PREFIX, OPEN);
pub const TOOLTIP_OPEN: &str = "Open...";
pub const ACCEL_OPEN: &str = concatcp!(PRIMARY, "o");

pub const TOGGLE_INSPECTOR: &str = "toggle-inspector";
pub const WIN_TOGGLE_INSPECTOR: &str = concatcp!(WIN_PREFIX, TOGGLE_INSPECTOR);
pub const ACCEL_TOGGLE_INSPECTOR: &str = "F9";

pub const TOGGLE_PREVIEW: &str = "toggle-preview";
pub const WIN_TOGGLE_PREVIEW: &str = concatcp!(WIN_PREFIX, TOGGLE_PREVIEW);
pub const ACCEL_TOGGLE_PREVIEW: &str = concatcp!(PRIMARY, "<shift>", "q");

pub const ABOUT: &str = "about";
pub const APP_ABOUT: &str = concatcp!(APP_PREFIX, "about");

pub const PREFERENCES: &str = "preferences";
pub const APP_PREFERENCES: &str = concatcp!(APP_PREFIX, PREFERENCES);
pub const ACCEL_PREFERENCES: &str = concatcp!(PRIMARY, "comma");

pub const WINDOW_CLOSE: &str = "window.close";
pub const ACCEL_WINDOW_CLOSE: &str = concatcp!(PRIMARY, "w");
pub const TOOLTIP_WINDOW_CLOSE: &str = "Close window";

pub const QUIT: &str = "quit";
pub const APP_QUIT: &str = concatcp!(APP_PREFIX, QUIT);
pub const ACCEL_QUIT: &str = concatcp!(PRIMARY, "q");
pub const TOOLTIP_QUIT: &str = "Quit";

pub const NEW_WINDOW: &str = "new-window";
pub const TOOLTIP_NEW_WINDOW: &str = "New window";
pub const APP_NEW_WINDOW: &str = concatcp!(APP_PREFIX, NEW_WINDOW);
pub const ACCEL_NEW_WINDOW: &str = concatcp!(PRIMARY, "n");

pub const SHORTCUTS: &str = "shortcuts";
pub const APP_SHORTCUTS: &str = concatcp!(APP_PREFIX, SHORTCUTS);
pub const ACCEL_SHORTCUTS: &str = concatcp!(PRIMARY, "question");
