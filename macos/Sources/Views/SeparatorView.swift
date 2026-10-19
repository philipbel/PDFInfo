// Copyright (c) 2026 Philip B. (philipbel)
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import Cocoa

final class SeparatorView: NSBox {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        boxType = .separator
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
