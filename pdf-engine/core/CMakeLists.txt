cmake_minimum_required(VERSION 3.16)

set(CMAKE_OSX_DEPLOYMENT_TARGET 14.0 CACHE STRING "")

project (pdf-engine-core VERSION 1.0.0 LANGUAGES CXX)
set (CMAKE_CXX_STANDARD 20)
set (CMAKE_CXX_EXTENSIONS OFF)
set (CMAKE_CXX_STANDARD_REQUIRED ON)
set (CMAKE_CXX_VISIBILITY_PRESET hidden)
set (CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package (qpdf CONFIG REQUIRED)

set (SRCS
    src/document.cc
    src/font_descriptor.cc
    src/font_program.cc
    src/font.cc
    src/metadata.cc
    src/page_size.cc
)

add_library (pdf-engine-core STATIC
    ${SRCS}
)
if (NOT MSVC)
    target_compile_options(pdf-engine-core PRIVATE
        -Wall
        -Wextra
        -Wpedantic
        -Werror
        -Wimplicit-fallthrough
        -Wreturn-type
    )
endif ()
target_include_directories(pdf-engine-core
    PUBLIC include)
target_link_libraries(pdf-engine-core PRIVATE qpdf::libqpdf)

install(TARGETS pdf-engine-core ARCHIVE DESTINATION lib)
install(
    DIRECTORY include/pdf-engine
    DESTINATION include)
