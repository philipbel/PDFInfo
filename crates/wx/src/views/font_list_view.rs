// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::rc::Rc;

use log::{
    debug,
    warn,
};
use strum::{
    EnumCount,
    EnumIter,
    FromRepr,
    IntoEnumIterator,
};
use wxdragon::prelude::*;

use crate::models::{
    FontListModel,
    FontModel,
};
use crate::views::View;


pub(crate) struct FontListView {
    list_ctrl: DataViewListCtrl,
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
        let list_ctrl = DataViewListCtrl::builder(parent)
            .with_style(DataViewStyle::Single)
            .build();
        Self::init_list(&list_ctrl, model);
        _ = list_ctrl.on_item_activated(|e| {
            debug!("on_item_selected: {:?}", e.get_item());
        });

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

    fn init_list(list_ctrl: &DataViewListCtrl, model: Rc<impl FontListModel + 'static>) {
        // 1. Set up the columns. They're sizes according to the headers
        for (col_index, column) in Column::iter().enumerate() {
            // TODO: wxDragon doesn't expose wxListCtrl::AppendColumn.
            _ = list_ctrl.append_text_column(
                &Self::label_for_column(column),
                col_index,
                DataViewAlign::Left | DataViewAlign::CenterVertical,
                -2, // XXX: wxCOL_WIDTH_AUTOSIZE
                DataViewColumnFlags::Resizable | DataViewColumnFlags::Sortable,
            );
        }
        for font in model.fonts() {
            let item_values = Column::iter()
                .map(|c| Self::item_text(c, font))
                .map(Variant::from_string)
                .collect::<Vec<Variant>>();
            _ = list_ctrl.append_item(&item_values);
        }
        // // 2. Insert the items
        // for (item_index, font) in model.fonts().iter().enumerate() {
        //     // 2a) set the first column only, which is the only way to actually create new rows
        //     _ = list_ctrl.insert_item(
        //         item_index as i64,
        //         &Self::item_text(Column::Name, font),
        //         None,
        //     );
        //     // 2b) Now set the rest
        //     for col_index in 1..Column::COUNT {
        //         let column = Column::from_repr(col_index as i32).expect("Invalid column");
        //         list_ctrl.set_item_text_by_column(
        //             item_index as i64,
        //             col_index as i32,
        //             &Self::item_text(column, font),
        //         );
        //     }
        // }
        // // 3. Now that all items are in the list control, autosize the columns
        // for (col_index, column) in Column::iter().enumerate() {
        //     list_ctrl.set_column_width(col_index as i64, Self::column_width(column));
        // }
        // 4. Finally, size the first column so that it takes all available space...
        // list_ctrl.layout(); // Doesn't seem to be needed, but it probably doesn't hurt either
        // let min_first_column_width = list_ctrl.get_column_width(0); // as laid out.
        // {
        //     let list_ctrl = *list_ctrl;
        //     _ = list_ctrl.bind_internal(EventType::SIZE, move |e| {
        //         let total_width: i32 = (1..list_ctrl.get_item_count())
        //             .map(|c| list_ctrl.)
        //             .sum();
        //         let list_width = list_ctrl.get_client_size().width;
        //         let new_first_column_width =
        //             (list_width - total_width).max(min_first_column_width);
        //         list_ctrl.set_column_width(0, new_first_column_width);
        //         e.skip(true);
        //     });
        // }
        // XXX: wxDragon doesn't expose GetColumnCount() and GetColumn()
    }

    fn item_text(column: Column, font: &FontModel) -> String {
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
            Column::Embedded => WX_LIST_AUTOSIZE_USEHEADER,
            Column::Installed => WX_LIST_AUTOSIZE_USEHEADER,
        }
    }
}


impl View for FontListView {
    type Root = DataViewListCtrl;

    fn root_view(&self) -> Self::Root {
        self.list_ctrl
    }
}
