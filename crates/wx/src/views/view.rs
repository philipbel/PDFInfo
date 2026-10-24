// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use wxdragon::WxWidget;


pub(crate) trait View {
    type Root: WxWidget;
    fn root_view(&self) -> Self::Root;
}
