// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

// cSpell: words HRESULT

#include "font-locator.hh"
#include <dwrite_3.h>
#include <optional>
#include <utility>
#include <vector>
#include <wrl/client.h>


using namespace std;
using Microsoft::WRL::ComPtr;


namespace {

string toUTF8(wstring_view utf16) {
    if (utf16.empty()) {
        return {};
    }
    const int size =
        WideCharToMultiByte(CP_UTF8, 0, utf16.data(), utf16.size(), nullptr, 0, nullptr, nullptr);
    if (size <= 0) {
        return {};
    }
    string utf8(size, '\0');
    (void)WideCharToMultiByte(
        CP_UTF8, 0, utf16.data(), utf16.size(), utf8.data(), utf8.size(), nullptr, nullptr);
    return utf8;
}

wstring getLocaleName() {
    wstring localeName(LOCALE_NAME_MAX_LENGTH, L'\0');
    const auto length = GetUserDefaultLocaleName(localeName.data(), localeName.size());
    if (length > 0) {
        localeName.resize(length - 1);
        return localeName;
    }
    return L"en-us";
}


optional<wstring> getProperty(const ComPtr<IDWriteFontSet> &fontSet, UINT32 fontIndex,
                              DWRITE_FONT_PROPERTY_ID propertyID, const wstring &localeName) {
    BOOL exists = FALSE;
    ComPtr<IDWriteLocalizedStrings> localizedStrings;
    HRESULT hr = fontSet->GetPropertyValues(fontIndex, propertyID, &exists, &localizedStrings);
    if (FAILED(hr) || !exists) {
        return nullopt;
    }
    UINT32 localeIndex = UINT_MAX;
    BOOL localeNameExists = FALSE;
    hr = localizedStrings->FindLocaleName(localeName.c_str(), &localeIndex, &localeNameExists);
    if (FAILED(hr)) {
        return nullopt;
    }
    if (!localeNameExists) {
        localeIndex = 0;
    }
    UINT32 stringLength = 0;
    hr = localizedStrings->GetStringLength(localeIndex, &stringLength);
    if (FAILED(hr)) {
        return nullopt;
    }
    wstring stringValue(stringLength + 1, L'\0');
    hr = localizedStrings->GetString(localeIndex, stringValue.data(), stringValue.size());
    if (FAILED(hr)) {
        return nullopt;
    }
    stringValue.resize(stringLength);
    return stringValue;
}


optional<wstring> getFontFile(const ComPtr<IDWriteFontSet> &fontSet, UINT32 fontIndex) {
    HRESULT hr;
    ComPtr<IDWriteFontFaceReference> fontFaceReference;
    hr = fontSet->GetFontFaceReference(fontIndex, &fontFaceReference);
    if (FAILED(hr)) {
        return nullopt;
    }
    ComPtr<IDWriteFontFile> fontFile;
    hr = fontFaceReference->GetFontFile(&fontFile);
    if (FAILED(hr)) {
        return nullopt;
    }
    const void *fontFileReferenceKey;
    UINT32 fontFileReferenceKeySize;
    hr = fontFile->GetReferenceKey(&fontFileReferenceKey, &fontFileReferenceKeySize);
    if (FAILED(hr)) {
        return nullopt;
    }
    ComPtr<IDWriteFontFileLoader> fontFileLoader;
    hr = fontFile->GetLoader(&fontFileLoader);
    if (FAILED(hr)) {
        return nullopt;
    }
    ComPtr<IDWriteLocalFontFileLoader> localFontFileLoader;
    hr = fontFileLoader.As(&localFontFileLoader);
    if (FAILED(hr)) {
        return nullopt;
    }
    UINT filePathLength;
    hr = localFontFileLoader->GetFilePathLengthFromKey(
        fontFileReferenceKey, fontFileReferenceKeySize, &filePathLength);
    if (FAILED(hr)) {
        return nullopt;
    }
    wstring filePath(filePathLength + 1, L'\0');
    hr = localFontFileLoader->GetFilePathFromKey(
        fontFileReferenceKey, fontFileReferenceKeySize, filePath.data(), filePath.size());
    if (FAILED(hr)) {
        return nullopt;
    }
    filePath.resize(filePathLength);
    return filePath;
}


} // namespace


namespace internal {


void enumerateSystemFonts() {
    const auto localeName = getLocaleName();
    ComPtr<IDWriteFactory3> factory;
    HRESULT hr;

    hr = DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, __uuidof(IDWriteFactory3), &factory);
    if (FAILED(hr)) {
        return;
    }
    ComPtr<IDWriteFontSet> fontSet;
    hr = factory->GetSystemFontSet(&fontSet);
    if (FAILED(hr)) {
        return;
    }

    vector<pair<string, font_locator_font>> psNamedFonts;
    vector<pair<string, font_locator_font>> otherFonts;

    const auto fontCount = fontSet->GetFontCount();
    for (UINT32 i = 0; i < fontCount; ++i) {
        const auto postscriptName =
            getProperty(fontSet, i, DWRITE_FONT_PROPERTY_ID_POSTSCRIPT_NAME, localeName);
        if (!postscriptName) {
            continue;
        }
        const auto filePath = getFontFile(fontSet, i);
        if (!filePath) {
            continue;
        }
        const auto family =
            getProperty(fontSet, i, DWRITE_FONT_PROPERTY_ID_FAMILY_NAME, localeName);
        const auto style = getProperty(
            fontSet, i, DWRITE_FONT_PROPERTY_ID_WEIGHT_STRETCH_STYLE_FACE_NAME, localeName);

        const auto locatedFont = font_locator_font{
            .postscript_name = toUTF8(*postscriptName),
            .path = toUTF8(*filePath),
        };
        psNamedFonts.emplace_back(locatedFont.postscript_name, locatedFont);

        if (family) {
            const auto familyUTF8 = toUTF8(*family);
            otherFonts.emplace_back(familyUTF8, locatedFont);
            if (style) {
                otherFonts.emplace_back(familyUTF8 + toUTF8(*style), locatedFont);
            }
        }
    }
}

} // namespace internal
