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

project(pdf-engine-core VERSION 1.0.0 LANGUAGES C CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_VISIBILITY_PRESET hidden)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(USE_SYSTEM_LIBS FALSE CACHE BOOL 
    "Use system-provided libraries. If FALSE, build vendored dependencies.")

include(deps.cmake)

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
    target_include_directories(PDFEngineCore PUBLIC include)
    target_link_libraries(PDFEngineCore PRIVATE qpdf::libqpdf)

    add_custom_command(TARGET PDFEngineCore POST_BUILD
        # Merge the dependencies into a single library
        COMMAND libtool -static -no_warning_for_no_symbols
            -o $<TARGET_FILE:PDFEngineCore>.merged
            $<TARGET_FILE:PDFEngineCore>
            ${z-lib} ${jpeg-lib} ${qpdf-lib}
        COMMAND ${CMAKE_COMMAND} -E rename
            $<TARGET_FILE:PDFEngineCore>.merged $<TARGET_FILE:PDFEngineCore>
        COMMAND ${CMAKE_COMMAND} -E create_symlink
            Versions/Current/Modules $<TARGET_BUNDLE_DIR:PDFEngineCore>/Modules
        # Copy headers
        COMMAND ${CMAKE_COMMAND} -E copy_if_different ${HDRS}
            $<TARGET_BUNDLE_CONTENT_DIR:PDFEngineCore>/Headers
        # Copy module map
        COMMAND ${CMAKE_COMMAND} -E copy_if_different ${MODULEMAP}
            $<TARGET_BUNDLE_CONTENT_DIR:PDFEngineCore>/Modules
    )
    
    install(TARGETS PDFEngineCore FRAMEWORK DESTINATION lib)
endif ()

# pkg-config
if(USE_SYSTEM_LIBS)
    set(PC_REQUIRES_PRIVATE "libqpdf")
    set(PC_LIBS_PRIVATE "")
else()
    set(PC_REQUIRES_PRIVATE "")
    set(PC_LIBS_PRIVATE "-lqpdf -ljpeg -lz")
endif()
if(APPLE)
    string(APPEND PC_LIBS_PRIVATE " -lc++")
elseif(UNIX)
    string(APPEND PC_LIBS_PRIVATE " -lstdc++")
endif()

configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/pdf-engine-core.pc.in 
    ${CMAKE_CURRENT_BINARY_DIR}/pdf-engine-core.pc
    @ONLY)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/pdf-engine-core.pc
    DESTINATION lib/pkgconfig)


set(COMPILE_COMMANDS_DIR ${PROJECT_SOURCE_DIR}/../../build/compile_commands)
add_custom_target(copy-compile-commands ALL
    COMMAND ${CMAKE_COMMAND} -E make_directory ${COMPILE_COMMANDS_DIR}
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        ${CMAKE_BINARY_DIR}/compile_commands.json
        ${COMPILE_COMMANDS_DIR}/pdf-engine-core.json
)
