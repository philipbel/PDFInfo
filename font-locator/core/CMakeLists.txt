# Copyright (c) 2026 Philip B. (philipbel)
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

cmake_minimum_required(VERSION 3.16)

set(CMAKE_OSX_DEPLOYMENT_TARGET 14.0 CACHE STRING "")

project (font-locator VERSION 1.0.0 LANGUAGES CXX)
set (CMAKE_CXX_STANDARD 20)
set (CMAKE_CXX_EXTENSIONS OFF)
set (CMAKE_CXX_STANDARD_REQUIRED ON)
set (CMAKE_CXX_VISIBILITY_PRESET hidden)
set (CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Not currently used
set(DEPS_UNIVERSAL_LIB_DIR "" CACHE PATH "(macOS) Directory containing dependencies' static universal libs")


if(NOT MSVC)
    add_compile_options(
        -Wall
        -Wextra
        -Wpedantic
        -Werror
        -Wimplicit-fallthrough
        -Wreturn-type
    )
endif()

set(SRCS ${CMAKE_CURRENT_SOURCE_DIR}/src/font-locator.cc)
if(APPLE)
    list(APPEND SRCS ${CMAKE_CURRENT_SOURCE_DIR}/src/font-locator-macos.cc)
elseif(LINUX)
    list(APPEND SRCS ${CMAKE_CURRENT_SOURCE_DIR}/src/font-locator-linux.cc)
endif()

set(HDRS ${CMAKE_CURRENT_SOURCE_DIR}/include/font-locator/font-locator.h)
set(MODULEMAP ${CMAKE_CURRENT_SOURCE_DIR}/module.modulemap)

add_library(font-locator-objs OBJECT ${SRCS})
target_include_directories(font-locator-objs PUBLIC include)

add_library(font-locator-core STATIC $<TARGET_OBJECTS:font-locator-objs>)
target_include_directories(font-locator-core PUBLIC include)

if(APPLE)
    find_library(CORE_TEXT CoreText REQUIRED)
    find_library(CORE_FOUNDATION CoreFoundation REQUIRED)
    target_link_libraries(font-locator-core PRIVATE ${CORE_TEXT} ${CORE_FOUNDATION})
elseif(LINUX)
    find_package(Fontconfig REQUIRED)
    target_link_libraries(font-locator-objs PRIVATE Fontconfig::Fontconfig)
endif()

install(TARGETS font-locator-core ARCHIVE DESTINATION lib)
install(
    DIRECTORY include/font-locator
    DESTINATION include)


# macOS Framework
if (APPLE)
    add_library(FontLocatorCore STATIC
        $<TARGET_OBJECTS:font-locator-objs>
        ${HDRS}
        ${MODULEMAP}
    )
    set_source_files_properties(${MODULEMAP} PROPERTIES
        MACOSX_PACKAGE_LOCATION Modules
    )
    set_target_properties(FontLocatorCore PROPERTIES
        FRAMEWORK TRUE
        FRAMEWORK_VERSION A
        MACOSX_FRAMEWORK_IDENTIFIER com.github.philipbel.PDFInfo.FontLocatorCore
        VERSION 1.0.0
        SOVERSION 1.0.0
        PUBLIC_HEADER "${HDRS}"
    )
    target_include_directories(FontLocatorCore
        PUBLIC include)
    target_link_libraries(FontLocatorCore PRIVATE ${CORE_TEXT} ${CORE_FOUNDATION})

    add_custom_command(TARGET FontLocatorCore POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E create_symlink
            Versions/Current/Modules $<TARGET_BUNDLE_DIR:FontLocatorCore>/Modules
    )
    
    install(TARGETS FontLocatorCore FRAMEWORK DESTINATION lib)
endif ()
