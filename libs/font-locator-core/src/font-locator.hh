// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT


#pragma once

#include <font-locator/font-locator.h>
#include <string>
#include <string_view>

struct font_locator_font {
    std::string postscript_name;
    std::string path;
};

namespace internal {

extern std::string getKeyForFontName(std::string_view name);

extern const font_locator_font *findFontForKey(const std::string &key);
extern void maybeUpdateFontForKey(const std::string &key, const font_locator_font &font);

// Platform-specific
extern void enumerateSystemFonts();

} // namespace internal
