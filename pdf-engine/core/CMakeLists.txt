# Copyright (c) 2026 Philip B. (philipbel)
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

cmake_minimum_required(VERSION 3.16)

set(CMAKE_OSX_DEPLOYMENT_TARGET 14.0 CACHE STRING "")

project(pdf-engine-core VERSION 1.0.0 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_VISIBILITY_PRESET hidden)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(DEPS_UNIVERSAL_LIB_DIR "" CACHE PATH "(macOS) Directory containing dependencies' static universal libs")

if(APPLE)
    if(NOT DEPS_UNIVERSAL_LIB_DIR)
        message(FATAL_ERROR "DEPS_UNIVERSAL_LIB_DIR is required")
    endif()
endif()


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

find_package(qpdf CONFIG REQUIRED)

file(GLOB SRCS
    CONFIGURE_DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cc
)
file(GLOB HDRS
    CONFIGURE_DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/include/pdf-engine/*.h
)
set(MODULEMAP ${CMAKE_CURRENT_SOURCE_DIR}/module.modulemap)

add_library(pdf-engine-objs OBJECT ${SRCS})
target_include_directories(pdf-engine-objs PUBLIC include)
target_link_libraries(pdf-engine-objs PRIVATE qpdf::libqpdf)

add_library(pdf-engine-core STATIC $<TARGET_OBJECTS:pdf-engine-objs>)
target_include_directories(pdf-engine-core PUBLIC include)
target_link_libraries(pdf-engine-core PRIVATE qpdf::libqpdf)

install(TARGETS pdf-engine-core ARCHIVE DESTINATION lib)
install(
    DIRECTORY include/pdf-engine
    DESTINATION include)


if (APPLE)
    add_library(PDFEngineCore STATIC    
        $<TARGET_OBJECTS:pdf-engine-objs>
        ${HDRS}
        ${MODULEMAP}
    )
    set_source_files_properties(${MODULEMAP} PROPERTIES
        MACOSX_PACKAGE_LOCATION Modules
    )
    set_target_properties(PDFEngineCore PROPERTIES
        FRAMEWORK TRUE
        FRAMEWORK_VERSION A
        MACOSX_FRAMEWORK_IDENTIFIER com.github.philipbel.PDFInfo.PDFEngineCore
        VERSION 1.0.0
        SOVERSION 1.0.0
        PUBLIC_HEADER "${HDRS}"
    )
    target_include_directories(PDFEngineCore
        PUBLIC include)
    target_link_libraries(PDFEngineCore PRIVATE qpdf::libqpdf)

    # Merge the dependencies into a single library
    add_custom_command(TARGET PDFEngineCore POST_BUILD
        COMMAND libtool -static -o $<TARGET_FILE:PDFEngineCore>.merged
            $<TARGET_FILE:PDFEngineCore>
            ${DEPS_UNIVERSAL_LIB_DIR}/libqpdf.a
            ${DEPS_UNIVERSAL_LIB_DIR}/libjpeg.a
            ${DEPS_UNIVERSAL_LIB_DIR}/libz.a
        COMMAND ${CMAKE_COMMAND} -E rename
            $<TARGET_FILE:PDFEngineCore>.merged $<TARGET_FILE:PDFEngineCore>
        COMMAND ${CMAKE_COMMAND} -E create_symlink
            Versions/Current/Modules $<TARGET_BUNDLE_DIR:PDFEngineCore>/Modules
    )
    
    install(TARGETS PDFEngineCore FRAMEWORK DESTINATION lib)
endif ()
