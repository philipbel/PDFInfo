// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT


#pragma once

#include <optional>
#include <qpdf/QPDFObjectHandle.hh>
#include <string>
#include <string_view>


static inline std::optional<std::string> getUTF8String(const QPDFObjectHandle &dictionary,
                                                       const std::string_view key) {
    const auto value = dictionary.getKey(std::string(key));
    if (value.isString()) {
        std::string s;
        if (value.getValueAsUTF8(s)) {
            return std::move(s);
        }
    }
    return std::nullopt;
}
