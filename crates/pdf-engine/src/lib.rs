// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

mod descriptor;
mod document;
mod ffi;
mod font;
mod metadata;
mod page;
mod program;
mod version;

pub use descriptor::{
    Descriptor,
    DescriptorFlags,
};
pub use document::Document;
pub use font::{
    Font,
    FontDisplayType,
    FontId,
    FontSubtype,
};
pub use metadata::Metadata;
pub use page::{
    PageOrientation,
    PageSize,
    PaperSize,
};
pub use program::{
    Program,
    ProgramKind,
};
pub use version::Version;
