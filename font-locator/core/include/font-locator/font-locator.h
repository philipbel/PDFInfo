// Copyright (c) 2026 Philip B. (philipbel)
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT


#pragma once


#ifdef __cplusplus
extern "C" {
#endif


struct font_locator_font;

void font_locator_init(void);

/*
 * Returned pointer is owned by the library and points to static data that lives until the process
 * dies
 */
const struct font_locator_font *font_locator_find_font(const char *name);


/*
 * Returned pointer is owned by the library and points to static data that lives until the process
 * dies
 */
const char *font_locator_font_get_postscript_name(const struct font_locator_font *font);


/*
 * Returned pointer is owned by the library and points to static data that lives until the process
 * dies
 */
const char *font_locator_font_get_path(const struct font_locator_font *font);

#ifdef __cplusplus
}
#endif
