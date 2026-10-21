# Copyright (c) 2026 Philip B. (philipbel)
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# cSpell: ignoreRegExp -W\w+
# cSpell: ignoreRegExp -D\w+
# cSpell: ignoreRegExp -l\w+
# cSpell: words SRCS HDRS MODULEMAP modulemap objs

cmake_minimum_required(VERSION 3.28...4.2)
set(CMAKE_OSX_DEPLOYMENT_TARGET "14.0" CACHE STRING "macOS deployment target")

project (font-locator VERSION 1.0.0 LANGUAGES CXX)
set (CMAKE_CXX_STANDARD 20)
set (CMAKE_CXX_EXTENSIONS OFF)
set (CMAKE_CXX_STANDARD_REQUIRED ON)
set (CMAKE_CXX_VISIBILITY_PRESET hidden)
set (CMAKE_EXPORT_COMPILE_COMMANDS ON)

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
elseif(WIN32)
    message(FATAL_ERROR "Not implemented on Windows")
else()
    message(FATAL_ERROR "System not supported")
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
        # Copy headers
        COMMAND ${CMAKE_COMMAND} -E copy_if_different ${HDRS}
            $<TARGET_BUNDLE_CONTENT_DIR:FontLocatorCore>/Headers
        # Copy module map
        COMMAND ${CMAKE_COMMAND} -E copy_if_different ${MODULEMAP}
            $<TARGET_BUNDLE_CONTENT_DIR:FontLocatorCore>/Modules
    )
    
    install(TARGETS FontLocatorCore FRAMEWORK DESTINATION lib)
endif ()

# pkg-config
if(APPLE)
    set(PC_REQUIRES_PRIVATE "")
    set(PC_LIBS_PRIVATE "-lc++ -framework CoreText -framework CoreFoundation")
elseif(UNIX)
    set(PC_REQUIRES_PRIVATE "fontconfig")
    set(PC_LIBS_PRIVATE "-lstdc++")
endif()

configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/font-locator-core.pc.in 
    ${CMAKE_CURRENT_BINARY_DIR}/font-locator-core.pc
    @ONLY)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/font-locator-core.pc
    DESTINATION lib/pkgconfig)

set(COMPILE_COMMANDS_DIR ${PROJECT_SOURCE_DIR}/../../build/compile_commands)
add_custom_target(copy-compile-commands ALL
    COMMAND ${CMAKE_COMMAND} -E make_directory ${COMPILE_COMMANDS_DIR}
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        ${CMAKE_BINARY_DIR}/compile_commands.json
        ${COMPILE_COMMANDS_DIR}/font-locator-core.json
)
