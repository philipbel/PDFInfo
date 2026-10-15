// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

use std::any::type_name;
use std::fmt;
use std::hash::{
    Hash,
    Hasher,
};
use std::marker::PhantomData;
use std::ops::RangeInclusive;

use gtk::gio::SettingsSchemaKey;
use gtk::gio::prelude::SettingsExt;
use gtk::{
    gio,
    glib,
};
use thiserror::Error;

pub struct SchemaKey<T> {
    name: &'static str,
    _type: PhantomData<T>,
}

impl<T> SchemaKey<T> {
    const fn new(name: &'static str) -> Self {
        Self {
            name,
            _type: PhantomData,
        }
    }

    pub fn name(&self) -> &'static str {
        self.name
    }
}

impl<T> Clone for SchemaKey<T> {
    fn clone(&self) -> Self {
        *self
    }
}

impl<T> Copy for SchemaKey<T> {
}

impl<T> PartialEq for SchemaKey<T> {
    fn eq(&self, other: &Self) -> bool {
        self.name == other.name
    }
}

impl<T> Eq for SchemaKey<T> {
}

impl<T> Hash for SchemaKey<T> {
    fn hash<H: Hasher>(&self, state: &mut H) {
        self.name.hash(state)
    }
}

impl<T> fmt::Debug for SchemaKey<T> {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "SchemaKey({:?})", self.name)
    }
}

impl<T> fmt::Display for SchemaKey<T> {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        f.write_str(self.name)
    }
}


// Keys as in data/com.github.philipbel.PDFInfo.gschema.xml
pub mod schema_keys {
    use super::SchemaKey;

    pub const PREVIEW_FONT_TEXT: SchemaKey<String> = SchemaKey::new("preview-font-text");
    pub const PREVIEW_FONT_SIZE: SchemaKey<i32> = SchemaKey::new("preview-font-size");
    pub const SHOW_INSPECTOR: SchemaKey<bool> = SchemaKey::new("show-inspector");
    pub const SHOW_PREVIEW: SchemaKey<bool> = SchemaKey::new("show-preview");
    pub const WINDOW_WIDTH: SchemaKey<i32> = SchemaKey::new("window-width");
    pub const WINDOW_HEIGHT: SchemaKey<i32> = SchemaKey::new("window-height");
    pub const WINDOW_MAXIMIZED: SchemaKey<bool> = SchemaKey::new("window-maximized");
}


#[derive(Error, Debug)]
pub enum SchemaError {
    #[error("No schema")]
    NoSchema,
    #[error("Key '{0}' not found")]
    KeyNotFound(&'static str),
    #[error("Key '{0}' has no range")]
    NoRange(&'static str),
    #[error("Key '{key}' has invalid range kind '{kind}'")]
    InvalidRangeKind { key: String, kind: String },
    #[error("Key '{0}' has no range values")]
    MissingRangeValues(&'static str),
    #[error("Key '{0}' has no default value")]
    MissingDefaultValue(&'static str),
    #[error(
        "Invalid type for '{key}': schema_type={schema_type}, key_type={key_type} ({type_name})"
    )]
    WrongType {
        key: &'static str,
        schema_type: String,
        key_type: String,
        type_name: String,
    },
    #[error("Cannot set value for key)")]
    SetError(#[from] glib::error::BoolError),
}


pub trait SettingsExtensions {
    fn range<T: glib::variant::FromVariant>(&self, key: SchemaKey<T>) -> RangeInclusive<T>;
    fn try_range<T: glib::variant::FromVariant>(
        &self,
        key: SchemaKey<T>,
    ) -> Result<RangeInclusive<T>, SchemaError>;

    fn default<T: glib::variant::FromVariant>(&self, key: SchemaKey<T>) -> T;
    fn try_default<T: glib::variant::FromVariant>(
        &self,
        key: SchemaKey<T>,
    ) -> Result<T, SchemaError>;

    fn set_value_for_key<T: Into<glib::Variant> + glib::variant::StaticVariantType>(
        &self,
        key: SchemaKey<T>,
        value: T,
    );
    fn try_set_value_for_key<T: Into<glib::Variant> + glib::variant::StaticVariantType>(
        &self,
        key: SchemaKey<T>,
        value: T,
    ) -> Result<(), SchemaError>;
}

fn verify_type<T: glib::variant::StaticVariantType>(
    key: SchemaKey<T>,
    schema_key: &gio::SettingsSchemaKey,
) -> Result<(), SchemaError> {
    let schema_key_type = schema_key.value_type();
    let key_type = T::static_variant_type();
    if schema_key_type != key_type {
        Err(SchemaError::WrongType {
            key: key.name,
            schema_type: schema_key_type.to_string(),
            key_type: key_type.to_string(),
            type_name: type_name::<T>().to_string(),
        })
    } else {
        Ok(())
    }
}

fn schema_key<T: glib::variant::StaticVariantType>(
    key: SchemaKey<T>,
    settings: &gio::Settings,
) -> Result<SettingsSchemaKey, SchemaError> {
    let Some(schema) = settings.settings_schema() else {
        return Err(SchemaError::NoSchema);
    };
    let key_name: &'static str = key.name();
    if !schema.has_key(key_name) {
        return Err(SchemaError::KeyNotFound(key_name));
    }
    let sk = schema.key(key_name);
    verify_type(key, &sk)?;
    Ok(sk)
}

impl SettingsExtensions for gio::Settings {
    fn range<T: glib::variant::FromVariant>(&self, key: SchemaKey<T>) -> RangeInclusive<T> {
        self.try_range(key)
            .unwrap_or_else(|_| panic!("cannot get range for key {}", key.name))
    }

    fn try_range<T: glib::variant::FromVariant>(
        &self,
        key: SchemaKey<T>,
    ) -> Result<RangeInclusive<T>, SchemaError> {
        let sk = schema_key(key, self)?;

        let (kind, range) = sk
            .range()
            .get::<(String, glib::Variant)>()
            .ok_or(SchemaError::NoRange(key.name))?;
        if kind != "range" {
            return Err(SchemaError::InvalidRangeKind {
                key: sk.name().to_string(),
                kind,
            });
        }
        let Some((min, max)) = range.get::<(T, T)>() else {
            return Err(SchemaError::MissingRangeValues(key.name));
        };
        Ok(min..=max)
    }

    fn default<T: glib::variant::FromVariant>(&self, key: SchemaKey<T>) -> T {
        self.try_default(key)
            .unwrap_or_else(|_| panic!("cannot get default value for key {}", key.name))
    }

    fn try_default<T: glib::variant::FromVariant>(
        &self,
        key: SchemaKey<T>,
    ) -> Result<T, SchemaError> {
        let sk = schema_key(key, self)?;
        let Some(d) = sk.default_value().get::<T>() else {
            return Err(SchemaError::MissingDefaultValue(key.name));
        };
        Ok(d)
    }

    fn set_value_for_key<T: Into<glib::Variant> + glib::variant::StaticVariantType>(
        &self,
        key: SchemaKey<T>,
        value: T,
    ) {
        self.try_set_value_for_key(key, value)
            .unwrap_or_else(|_| panic!("Cannot set value for key '{}'", key));
    }

    fn try_set_value_for_key<T: Into<glib::Variant> + glib::variant::StaticVariantType>(
        &self,
        key: SchemaKey<T>,
        value: T,
    ) -> Result<(), SchemaError> {
        _ = schema_key(key, self)?;

        gio::prelude::SettingsExtManual::set(self, key.name, value).map_err(SchemaError::SetError)
    }
}
