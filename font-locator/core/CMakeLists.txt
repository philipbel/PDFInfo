# Copyright (c) 2026 Philip B. (philipbel)
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

cmake_minimum_required(VERSION 3.16)

set(CMAKE_OSX_DEPLOYMENT_TARGET 14.0 CACHE STRING "")

project (font-locator-core VERSION 1.0.0 LANGUAGES CXX)
set (CMAKE_CXX_STANDARD 20)
set (CMAKE_CXX_EXTENSIONS OFF)
set (CMAKE_CXX_STANDARD_REQUIRED ON)
set (CMAKE_CXX_VISIBILITY_PRESET hidden)
set (CMAKE_EXPORT_COMPILE_COMMANDS ON)

set (SRCS
    src/font-locator.cc
)

if (APPLE)
    list(APPEND SRCS src/font-locator-macos.cc)
endif (APPLE)


add_library (font-locator-core STATIC
    ${SRCS}
)

if(APPLE)
    find_library(CORE_TEXT CoreText REQUIRED)
    find_library(CORE_FOUNDATION CoreFoundation REQUIRED)
    target_link_libraries(font-locator-core PRIVATE ${CORE_TEXT} ${CORE_FOUNDATION})
endif()


if (NOT MSVC)
    target_compile_options(font-locator-core PRIVATE
        -Wall
        -Wextra
        -Wpedantic
        -Werror
        -Wimplicit-fallthrough
        -Wreturn-type
    )
endif ()


target_include_directories(font-locator-core
    PUBLIC include)

install(TARGETS font-locator-core ARCHIVE DESTINATION lib)
install(
    DIRECTORY include/font-locator
    DESTINATION include)
