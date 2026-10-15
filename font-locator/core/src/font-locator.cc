// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT


#include "font-locator.hh"
#include <cassert>
#include <cctype>
#include <mutex>
#include <unordered_map>

using namespace std;

static once_flag init_flag;
static unordered_map<string, font_locator_font> font_map;


static void doInit() {
    call_once(init_flag, enumerateSystemFonts);
}


string getKeyForFontName(string_view name) {
    // XXX: This doesn't handle Unicode
    string key;
    key.reserve(name.size());
    for (unsigned char c : name) {
        if (c == ' ' || c == '-') {
            continue;
        }
        key += static_cast<char>(tolower(c));
    }
    return key;
}


void font_locator_init() {
    try {
        doInit();
    } catch (...) {
        // TODO: Warn
    }
}


const struct font_locator_font *font_locator_find_font(const char *name) {
    if (name == nullptr) {
        return nullptr;
    }
    try {
        doInit();
        const auto key = getKeyForFontName(name);
        return findFontForKey(key);
    } catch (...) {
        // TODO: Warn
        return nullptr;
    }
}


const char *font_locator_font_get_postscript_name(const font_locator_font *font) {
    assert(font != nullptr);
    return font->postscript_name.c_str();
}


const char *font_locator_font_get_path(const font_locator_font *font) {
    assert(font != nullptr);
    return font->path.c_str();
}


const font_locator_font *findFontForKey(const string &key) {
    if (key.empty()) {
        return nullptr;
    }
    const auto iter = font_map.find(key);
    if (iter == font_map.end()) {
        return nullptr;
    }
    return &iter->second;
}


void maybeUpdateFontForKey(const std::string &key, const font_locator_font &font) {
    if (key.empty()) {
        return;
    }
    font_map.try_emplace(key, font);
}
