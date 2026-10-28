// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::rc::Rc;

use crate::models::FontModel;


pub(crate) trait FontListModel {
    fn fonts(&self) -> &[Rc<FontModel>];
}
