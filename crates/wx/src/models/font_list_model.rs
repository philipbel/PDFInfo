// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::rc::Rc;

use crate::models::FontModel;


pub(crate) trait FontListModel {
    fn font_count(&self) -> usize;
    fn font(&self, index: usize) -> Option<Rc<FontModel>>;
}
