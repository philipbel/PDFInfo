// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::ffi::c_int;

use anyhow::{
    Context,
    Result,
    anyhow,
};
use gettextrs::{
    LocaleCategory,
    bind_textdomain_codeset,
    bindtextdomain,
    setlocale,
    textdomain,
};
use log::debug;

pub fn init(domain: &str, locale_dir: &str) -> Result<()> {
    unsafe {
        _ = setlocale(LocaleCategory::LcAll, "").ok_or(anyhow!("setlocale() failed"))?;
    };
    let domain_dir = bindtextdomain(domain, locale_dir).with_context(|| {
        format!("bindtextdomain failed for domain {domain} and dirname {locale_dir}")
    })?;
    debug!("domain_dir: {}", domain_dir.display());

    let codeset = bind_textdomain_codeset(domain, "UTF-8")
        .with_context(|| format!("Failed to set codeset for domain {domain}"))?;
    debug!("codeset={codeset:?}");

    let text_domain =
        textdomain(domain).with_context(|| format!("Failed to set text domain to {domain}"))?;
    debug!("text domain set to {:?}", str::from_utf8(&text_domain));

    Ok(())
}

#[derive(Debug, Clone, Copy)]
pub enum MeasurementSystem {
    Metric,
    Us,
}

#[cfg(all(target_os = "linux", target_env = "gnu"))]
pub fn measurement_system() -> MeasurementSystem {
    // From man 7 locale.
    // LC_MEASUREMENT (GNU extension, since glibc 2.2) ...
    //
    // _NL_MEASUREMENT_MEASUREMENT [...] returns a pointer to a character that has the value 1
    // (metric) or 2 (US customary units).

    // From glibc's langinfo.h _NL_ITEM(category, index)	(((category) << 16) | (index))
    const NL_MEASUREMENT: libc::nl_item = (libc::LC_MEASUREMENT << 16) as libc::nl_item;
    match unsafe { libc::nl_langinfo(NL_MEASUREMENT).read() } {
        2 => MeasurementSystem::Us,
        _ => MeasurementSystem::Metric,
    }
}

#[cfg(target_os = "windows")]
pub fn measurement_system() -> MeasurementSystem {
    // Use GetLocaleInfoEx
    // See https://learn.microsoft.com/en-us/windows/win32/api/winnls/nf-winnls-getlocaleinfoex
    compile_error!()
}

#[cfg(target_os = "macos")]
pub fn measurement_system() -> MeasurementSystem {
    use objc2_foundation::NSLocale;
    if NSLocale::currentLocale().usesMetricSystem() {
        MeasurementSystem::Metric
    } else {
        MeasurementSystem::Us
    }
}

pub fn format_number(f: f64, decimals: u8) -> String {
    let s: glib::GString = unsafe {
        glib::translate::from_glib_full(glib::ffi::g_strdup_printf(
            c"%.*f".as_ptr(),
            decimals as c_int,
            f,
        ))
    };
    s.to_string()
}

#[cfg(not(any(
    all(target_os = "linux", target_env = "gnu"),
    target_os = "macos",
    target_os = "windows"
)))]
pub fn measurement_system() -> MeasurementSystem {
    #![feature(proc_macro_diagnostic)]
    use proc_macro::Diagnostic;
    Diagnostic::new()
        .warning("measurement_system() not implement for this platform, defaulting to metric")
        .emit();
    MeasurementSystem::Metric
}

/// Translate `msgid` with `gettext` and fill in the placeholders at runtime.
///
/// For malformed strings, the macro falls back to formatting `msgid`. If that fails, `msgid` is
/// used.
///
/// # Example:
/// ```ignore
/// let formatted_string = gettext_f("{foo} and {bar}", foo=1, bar=2");
/// ```
macro_rules! gettext_f {
    ($msgid:literal $(, $($args:tt)*)?) => {{
        let translated = ::gettextrs::gettext($msgid);
        ::formatx::formatx!(translated.as_str() $(, $($args)*)?).unwrap_or_else(|e| {
            ::log::warn!("bad translation for {:?}: {e}", $msgid);
            ::formatx::formatx!($msgid $(, $($args)*)?).unwrap_or_else(|_| $msgid.to_owned())
        })
    }};
}
pub(crate) use gettext_f;
