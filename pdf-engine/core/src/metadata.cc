// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

#include "metadata.hh"
#include "util.hh"
#include <algorithm>
#include <assert.h>
#include <chrono>
#include <qpdf/QUtil.hh>
#include <ranges>
#include <string_view>

using namespace std;


static string_view trim(string_view s) {
    constexpr string_view whitespace = " \t\r\n\f\v";
    const auto first = s.find_first_not_of(whitespace);
    if (first == string_view::npos) {
        return {};
    }
    const auto last = s.find_last_not_of(whitespace);
    return s.substr(first, last - first + 1);
}


static vector<string> parseKeywords(const string &s) {
    string str = s;
    ranges::replace(str, ';', ',');

    // clang-format off
    auto keywords = str
        | views::split(string_view{","}) 
        | views::transform([](auto &&str) {
            return string(trim(string_view(str.begin(), str.end())));
          })
        | views::filter([](const string &str) { return !str.empty(); });
    // clang-format on
    return vector(keywords.begin(), keywords.end());
}


static optional<time_t> parseDate(const string &s) {
    QUtil::QPDFTime qpdfTime;
    if (!QUtil::pdf_time_to_qpdf_time(s, &qpdfTime)) {
        return nullopt;
    }
    const auto date = chrono::year{qpdfTime.year} / qpdfTime.month / qpdfTime.day;
    if (!date.ok()) {
        return nullopt;
    }
    const auto time = chrono::hours{qpdfTime.hour}
        + chrono::minutes{qpdfTime.minute + qpdfTime.tz_delta} + chrono::seconds{qpdfTime.second};
    // sys_days returns seconds since epoch on C++20
    return (chrono::sys_days{date} + time).time_since_epoch().count();
}


optional<pdf_document_metadata> parseDocumentMetadata(QPDF &qpdf) {
    auto info = qpdf.getTrailer().getKey("/Info");
    if (!info.isDictionary()) {
        return nullopt;
    }
    pdf_document_metadata metadata;
    metadata.title = getUTF8String(info, "/Title");
    metadata.author = getUTF8String(info, "/Author");
    metadata.subject = getUTF8String(info, "/Subject");
    if (const auto s = getUTF8String(info, "/Keywords"); s) {
        metadata.keywords = parseKeywords(*s);
    }
    metadata.creator = getUTF8String(info, "/Creator");
    metadata.producer = getUTF8String(info, "/Producer");
    if (const auto s = getUTF8String(info, "/CreationDate"); s) {
        metadata.creation_date = parseDate(*s);
    }
    if (const auto s = getUTF8String(info, "/ModDate"); s) {
        metadata.mod_date = parseDate(*s);
    }
    if (string s; info.getKey("/Trapped").getValueAsName(s)) {
        if (s == "/True") {
            metadata.trapped = true;
        } else if (s == "/False") {
            metadata.trapped = false;
        } else {
            metadata.trapped = nullopt;
        }
    }
    return metadata;
}


const char *pdf_document_metadata_get_title(const struct pdf_document_metadata *m) {
    assert(m != nullptr);
    if (m->title) {
        return m->title->c_str();
    }
    return nullptr;
}


const char *pdf_document_metadata_get_author(const struct pdf_document_metadata *m) {
    assert(m != nullptr);
    if (m->author) {
        return m->author->c_str();
    }
    return nullptr;
}


const char *pdf_document_metadata_get_subject(const struct pdf_document_metadata *m) {
    assert(m != nullptr);
    if (m->subject) {
        return m->subject->c_str();
    }
    return nullptr;
}


size_t pdf_document_metadata_get_keyword_count(const struct pdf_document_metadata *m) {
    assert(m != nullptr);
    return m->keywords.size();
}


const char *pdf_document_metadata_get_keyword(const struct pdf_document_metadata *m, size_t n) {
    assert(m != nullptr);
    if (n >= m->keywords.size()) {
        return nullptr;
    }
    return m->keywords[n].c_str();
}


const char *pdf_document_metadata_get_creator(const struct pdf_document_metadata *m) {
    assert(m != nullptr);
    if (m->creator) {
        return m->creator->c_str();
    }
    return nullptr;
}


const char *pdf_document_metadata_get_producer(const struct pdf_document_metadata *m) {
    assert(m != nullptr);
    if (m->producer) {
        return m->producer->c_str();
    }
    return nullptr;
}


const int64_t *pdf_document_metadata_get_creation_date(const struct pdf_document_metadata *m) {
    assert(m != nullptr);
    if (m->creation_date) {
        return &*m->creation_date;
    }
    return nullptr;
}


const int64_t *pdf_document_metadata_get_mod_date(const struct pdf_document_metadata *m) {
    assert(m != nullptr);
    if (m->mod_date) {
        return &*m->mod_date;
    }
    return nullptr;
}


const bool *pdf_document_metadata_get_trapped(const struct pdf_document_metadata *m) {
    assert(m != nullptr);
    if (m->trapped) {
        return &*m->trapped;
    }
    return nullptr;
}
