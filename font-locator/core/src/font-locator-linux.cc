// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

#include "font-locator.hh"
#include <fontconfig/fontconfig.h>
#include <vector>


using namespace std;

namespace internal {


void enumerateSystemFonts() {
    vector<pair<string, font_locator_font>> psNamedFonts;
    vector<pair<string, font_locator_font>> otherFonts;

    // TODO: Handle exceptions

    auto config = FcInitLoadConfigAndFonts();
    auto objectSet = FcObjectSetBuild(FC_POSTSCRIPT_NAME, FC_FAMILY, FC_STYLE, FC_FILE, nullptr);
    auto pattern = FcPatternCreate();
    auto fontSet = FcFontList(config, pattern, objectSet);

    if (fontSet != nullptr) {
        for (int i = 0; i < fontSet->nfont; ++i) {
            const auto font = fontSet->fonts[i];
            FcChar8 *postscriptNameValue, *familyValue, *styleValue, *fileValue;
            if (FcPatternGetString(font, FC_POSTSCRIPT_NAME, 0, &postscriptNameValue)
                    == FcResultMatch
                && FcPatternGetString(font, FC_FAMILY, 0, &familyValue) == FcResultMatch
                && FcPatternGetString(font, FC_STYLE, 0, &styleValue) == FcResultMatch
                && FcPatternGetString(font, FC_FILE, 0, &fileValue) == FcResultMatch) {
                const auto postscriptName = string((const char *)postscriptNameValue);
                const auto family = string((const char *)familyValue);
                const auto style = string((const char *)styleValue);
                const auto file = string((const char *)fileValue);

                auto locatedFont = font_locator_font{
                    .postscript_name = postscriptName,
                    .path = file,
                };
                psNamedFonts.emplace_back(postscriptName, locatedFont);
                otherFonts.emplace_back(family, locatedFont);
                otherFonts.emplace_back(family + style, locatedFont);
            }
        }
    }

    FcFontSetDestroy(fontSet);
    FcPatternDestroy(pattern);
    FcObjectSetDestroy(objectSet);
    FcConfigDestroy(config);

    for (const auto &[name, font] : psNamedFonts) {
        const auto key = internal::getKeyForFontName(name);
        internal::maybeUpdateFontForKey(key, font);
    }

    for (const auto &[name, font] : otherFonts) {
        const auto key = internal::getKeyForFontName(name);
        internal::maybeUpdateFontForKey(key, font);
    }
}

} // namespace internal
