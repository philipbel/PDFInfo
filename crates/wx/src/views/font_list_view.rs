// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::rc::Rc;

use log::warn;
use strum::{
    EnumCount,
    EnumIter,
    FromRepr,
    IntoEnumIterator,
};
use wxdragon::{
    ListCtrl,
    ListCtrlStyle,
    WxWidget,
};

use crate::models::{
    FontListModel,
    FontModel,
};
use crate::views::View;


pub(crate) struct FontListView {
    list_ctrl: ListCtrl,
}


#[repr(i32)]
#[derive(EnumIter, FromRepr, EnumCount, Debug, Clone, Copy, PartialEq)]
enum Column {
    Name,
    Type,
    Embedded,
    Installed,
}

// TODO: wxDragon doesn't expose these...
const WX_LIST_AUTOSIZE: i32 = -1;
const WX_LIST_AUTOSIZE_USEHEADER: i32 = -2;


impl FontListView {
    pub(crate) fn new<P: WxWidget>(model: Rc<impl FontListModel + 'static>, parent: &P) -> Self {
        let list_ctrl = ListCtrl::builder(parent)
            .with_style(ListCtrlStyle::Report | ListCtrlStyle::SingleSel)
            .build();
        Self::init_list(&list_ctrl, model);

        Self { list_ctrl }
    }

    fn label_for_column(column: Column) -> String {
        // TODO: Translate
        match column {
            Column::Name => "Name",
            Column::Type => "Type",
            Column::Embedded => "Embedded",
            Column::Installed => "Installed",
        }
        .to_string()
    }

    fn init_list(list_ctrl: &ListCtrl, model: Rc<impl FontListModel + 'static>) {
        for (col_index, column) in Column::iter().enumerate() {
            // TODO: wxDragon doesn't expose wxListCtrl::AppendColumn.
            _ = list_ctrl.insert_column(
                col_index as i64,
                &Self::label_for_column(column),
                wxdragon::ListColumnFormat::Left,
                Self::column_width(column),
            );
        }
        // Now set the first column only, which is the only way to actually create new rows
        for item_index in 0..model.font_count() {
            let Some(font) = model.font(item_index) else {
                warn!("Cannot obtain font at {item_index}");
                continue;
            };
            list_ctrl.insert_item(
                item_index as i64,
                &Self::item_text(Column::Name, font),
                None,
            );
        }
        // Now set the rest
        for col_index in 1..Column::COUNT {
            let column = Column::from_repr(col_index as i32).expect("Invalid column");
            for item_index in 0..model.font_count() {
                let Some(font) = model.font(item_index) else {
                    warn!("Cannot obtain font at {item_index}");
                    continue;
                };
                list_ctrl.set_item_text_by_column(
                    item_index as i64,
                    col_index as i32,
                    &Self::item_text(column, font),
                );
            }
        }
        // Now that all items are in the list control, autosize the columns
        for (col_index, column) in Column::iter().enumerate() {
            list_ctrl.set_column_width(col_index as i64, Self::item_width(column));
        }
    }

    fn item_text(column: Column, font: Rc<FontModel>) -> String {
        match column {
            Column::Name => font.display_name.clone(),
            Column::Type => font.display_type.clone(),
            // TODO: Translate
            Column::Embedded => if font.is_embedded { "Yes" } else { "No" }.to_string(),
            // TODO: Translate
            Column::Installed => if font.is_installed { "Yes" } else { "No" }.to_string(),
        }
    }

    fn column_width(column: Column) -> i32 {
        match column {
            Column::Name => WX_LIST_AUTOSIZE,
            Column::Type => WX_LIST_AUTOSIZE,
            Column::Embedded => WX_LIST_AUTOSIZE,
            Column::Installed => WX_LIST_AUTOSIZE_USEHEADER,
        }
    }

    fn item_width(column: Column) -> i32 {
        match column {
            Column::Name => WX_LIST_AUTOSIZE,
            Column::Type => WX_LIST_AUTOSIZE,
            Column::Embedded => WX_LIST_AUTOSIZE_USEHEADER,
            Column::Installed => WX_LIST_AUTOSIZE_USEHEADER,
        }
    }
}


impl View for FontListView {
    type Root = ListCtrl;

    fn root_view(&self) -> Self::Root {
        self.list_ctrl
    }
}
