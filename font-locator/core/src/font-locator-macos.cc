// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

#include "font-locator.hh"
#include <CoreFoundation/CFArray.h>
#include <CoreText/CoreText.h>
#include <climits>
#include <memory>
#include <type_traits>
#include <vector>

using namespace std;

namespace {

struct CFReleaser {
    void operator()(CFTypeRef ref) const {
        if (ref) {
            CFRelease(ref);
        }
    }
};

template <typename Ref> using CFPtr = std::unique_ptr<std::remove_pointer_t<Ref>, CFReleaser>;


string CFStringToString(CFStringRef cfString) {
    if (!cfString) {
        return {};
    }
    // CFStringGetCStringPtr can return NULL indicating we need to allocate memory and use
    // CFStringGetBytes()
    if (const char *ptr = CFStringGetCStringPtr(cfString, kCFStringEncodingUTF8); ptr != nullptr) {
        return string{ptr};
    }
    const auto length = CFStringGetLength(cfString);
    const size_t maxSize = CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingUTF8);
    string s(maxSize, '\0');
    CFIndex actualSize = 0;
    (void)CFStringGetBytes(cfString,
                           CFRangeMake(0, length),
                           kCFStringEncodingUTF8,
                           0,     // lossByte
                           false, // isExternalRepresentation
                           reinterpret_cast<UInt8 *>(s.data()),
                           maxSize,
                           &actualSize);
    s.resize(actualSize);
    return s;
}

string CFURLGetFileSystemPath(CFURLRef url) {
    char buffer[PATH_MAX];
    if (!CFURLGetFileSystemRepresentation(url, true, (UInt8 *)buffer, PATH_MAX)) {
        return {};
    }
    return string{buffer};
}

} // namespace


namespace internal {


void enumerateSystemFonts() {
    CFPtr<CTFontCollectionRef> collection{CTFontCollectionCreateFromAvailableFonts(nullptr)};
    if (!collection) {
        return;
    }
    CFPtr<CFArrayRef> descriptors{CTFontCollectionCreateMatchingFontDescriptors(collection.get())};
    if (!descriptors) {
        return;
    }
    vector<pair<string, font_locator_font>> psNamedFonts;
    vector<pair<string, font_locator_font>> otherFonts;

    for (CFIndex i = 0; i < CFArrayGetCount(descriptors.get()); ++i) {
        const auto descriptor = (CTFontDescriptorRef)CFArrayGetValueAtIndex(descriptors.get(), i);
        if (!descriptor || CFGetTypeID(descriptor) != CTFontDescriptorGetTypeID()) {
            continue;
        }
        CFPtr<CFStringRef> psNameAttrib{
            (CFStringRef)CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute)};
        if (!psNameAttrib || CFGetTypeID(psNameAttrib.get()) != CFStringGetTypeID()) {
            continue;
        }
        const auto psName = CFStringToString(psNameAttrib.get());
        if (psName.empty()) {
            continue;
        }

        CFPtr<CFURLRef> pathURLAttrib{
            (CFURLRef)CTFontDescriptorCopyAttribute(descriptor, kCTFontURLAttribute)};
        if (!pathURLAttrib || CFGetTypeID(pathURLAttrib.get()) != CFURLGetTypeID()) {
            continue;
        }
        const auto path = CFURLGetFileSystemPath(pathURLAttrib.get());
        if (path.empty()) {
            continue;
        }

        const auto font = font_locator_font{.postscript_name = psName, .path = path};
        psNamedFonts.emplace_back(psName, font);

        CFPtr<CFStringRef> displayNameAttrib{
            (CFStringRef)CTFontDescriptorCopyAttribute(descriptor, kCTFontDisplayNameAttribute)};
        if (displayNameAttrib && CFGetTypeID(displayNameAttrib.get()) != CFStringGetTypeID()) {
            continue;
        }

        CFPtr<CFStringRef> familyNameAttrib{
            (CFStringRef)CTFontDescriptorCopyAttribute(descriptor, kCTFontFamilyNameAttribute)};
        if (familyNameAttrib && CFGetTypeID(familyNameAttrib.get()) != CFStringGetTypeID()) {
            continue;
        }

        CFPtr<CFStringRef> styleNameAttrib{
            (CFStringRef)CTFontDescriptorCopyAttribute(descriptor, kCTFontStyleNameAttribute)};
        if (styleNameAttrib && CFGetTypeID(styleNameAttrib.get()) != CFStringGetTypeID()) {
            continue;
        }

        auto displayName = CFStringToString(displayNameAttrib.get());
        if (!displayName.empty()) {
            otherFonts.emplace_back(displayName, font);
        }
        auto familyName = CFStringToString(familyNameAttrib.get());
        auto styleName = CFStringToString(styleNameAttrib.get());
        if (!familyName.empty() && !styleName.empty()) {
            otherFonts.emplace_back(familyName + styleName, font);
        }
    }

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
