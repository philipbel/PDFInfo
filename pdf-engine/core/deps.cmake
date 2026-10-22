# Copyright (c) 2026 Philip B. (philipbel)
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT


function(fetch_dep NAME URL HASH)
    ExternalProject_Add(${NAME}-src
        URL ${URL}
        URL_HASH SHA256=${HASH}
        DOWNLOAD_DIR ${DEPS_DOWNLOAD_DIR}
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
        SOURCE_DIR ${DEPS_SRC_DIR}/${NAME}
        CONFIGURE_COMMAND "" BUILD_COMMAND "" INSTALL_COMMAND ""
    )
endfunction()


function(build_dependencies ARCH PREFIX)
    set(args 
        # Build and install into the arch-dependant prefix
        -DCMAKE_INSTALL_PREFIX=${PREFIX} 
        -DCMAKE_PREFIX_PATH=${PREFIX}
        -DCMAKE_INSTALL_LIBDIR=lib # no lib64 on Linux
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        # -DCMAKE_DISABLE_FIND_PACKAGE_PkgConfig=ON # disable pkg-config
        # Forward compilers and flags
        -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}        
        -DCMAKE_C_FLAGS=${CMAKE_C_FLAGS}
        -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
        -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
    )
    if(APPLE)
        if(ARCH)
            set(suffix "-${ARCH}")
            list(APPEND args -DCMAKE_OSX_ARCHITECTURES=${ARCH})
        endif()
        if(CMAKE_OSX_DEPLOYMENT_TARGET)
            list(APPEND args
                -DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}
            )
        endif()
    endif()

    set(z-lib${suffix} ${PREFIX}/lib/${z-libfile})
    ExternalProject_Add(z-build${suffix}
        DEPENDS z-src
        DOWNLOAD_COMMAND ""
        SOURCE_DIR ${DEPS_SRC_DIR}/z
        CMAKE_ARGS ${args}
            -DZLIB_COMPAT=ON
            -DBUILD_TESTING=OFF
            -DBUILD_SHARED_LIBS=OFF
            -DWITH_OPTIM=ON
        INSTALL_BYPRODUCTS ${z-lib${suffix}}
    )
    set(jpeg-lib${suffix} ${PREFIX}/lib/${jpeg-libfile})
    ExternalProject_Add(jpeg-build${suffix}
        DEPENDS jpeg-src
        DOWNLOAD_COMMAND ""
        SOURCE_DIR ${DEPS_SRC_DIR}/jpeg
        CMAKE_ARGS ${args}
            -DENABLE_SHARED=OFF
            -DENABLE_STATIC=ON
            -DWITH_SIMD=OFF
            -DWITH_TURBOJPEG=OFF
            -DWITH_TOOLS=OFF
        INSTALL_BYPRODUCTS ${jpeg-lib${suffix}}
    )
    # libjpeg is named differently on Windows and qpdf fails to find it
    # Ditto for zlib.
    if(WIN32)
        if(CMAKE_BUILD_TYPE STREQUAL "Debug")
            set(ZLIB_DEBUG_POSTFIX "d")
        else()
            set(ZLIB_DEBUG_POSTFIX "")
        endif()

        ExternalProject_Add_Step(z-build${suffix} rename-lib
            COMMAND ${CMAKE_COMMAND} -E rename
                ${PREFIX}/lib/zlibstatic${ZLIB_DEBUG_POSTFIX}.lib
                ${PREFIX}/lib/z.lib
            DEPENDEES install
            DEPENDERS done
            COMMENT "Rename zlib's static library"
        )
        ExternalProject_Add_Step(jpeg-build${suffix} rename-lib
            COMMAND ${CMAKE_COMMAND} -E rename
                ${PREFIX}/lib/jpeg-static.lib
                ${PREFIX}/lib/jpeg.lib
            DEPENDEES install
            DEPENDERS done
            COMMENT "Rename zlib's static library"
        )
    endif()
    set(qpdf-lib${suffix} ${PREFIX}/lib/${qpdf-libfile})
    ExternalProject_Add(qpdf-build${suffix}
        DEPENDS qpdf-src z-build${suffix} jpeg-build${suffix}
        DOWNLOAD_COMMAND ""
        SOURCE_DIR ${DEPS_SRC_DIR}/qpdf
        CMAKE_ARGS ${args}
            -DBUILD_SHARED_LIBS=OFF
            -DBUILD_STATIC_LIBS=ON
            -DUSE_IMPLICIT_CRYPTO=OFF
            -DREQUIRE_CRYPTO_NATIVE=ON
            -DSTATIC_JPEG=ON
            -DINSTALL_EXAMPLES=OFF
            -DGENERATE_AUTO_JOB=OFF
        INSTALL_BYPRODUCTS ${qpdf-lib${suffix}}
    )

    return(PROPAGATE
        z-lib${suffix}
        jpeg-lib${suffix}
        qpdf-lib${suffix}
    )
endfunction()



# For each lib, the following variables are set
# <lib>-src - the target that fetches the source
# <lib>-libfile - name of the lib, e.g. libz.a
# <lib>-lib - path to the library (universal on macOS)
# <lib>-lib-<arch> - (optional, macOS) path to the per-arch library
# <lib>-build - the target that builds <lib>

if(USE_SYSTEM_LIBS)
    message(FATAL_ERROR "Not implemented")
else()
    include(ExternalProject)
    set(DEPS_PREFIX_DIR "${CMAKE_BINARY_DIR}/deps")
    set(DEPS_SRC_DIR "${CMAKE_BINARY_DIR}/deps/src")
    cmake_path(SET download_dir NORMALIZE "${PROJECT_SOURCE_DIR}/../../build/download")
    set(DEPS_DOWNLOAD_DIR "${download_dir}" CACHE PATH "Shared download cache")


    set (LIBS z jpeg qpdf)
    foreach(lib IN LISTS LIBS)
        set(${lib}-libfile ${CMAKE_STATIC_LIBRARY_PREFIX}${lib}${CMAKE_STATIC_LIBRARY_SUFFIX})
    endforeach()

    file(MAKE_DIRECTORY ${DEPS_PREFIX_DIR}/include)
    file(MAKE_DIRECTORY ${DEPS_PREFIX_DIR}/lib)

    fetch_dep(z
        https://github.com/zlib-ng/zlib-ng/archive/refs/tags/2.3.3.tar.gz
        f9c65aa9c852eb8255b636fd9f07ce1c406f061ec19a2e7d508b318ca0c907d1
    )
    fetch_dep(jpeg
        https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/3.2.0/libjpeg-turbo-3.2.0.tar.gz
        6f30092cef9fb839779646608f4ee14ae3cbac989c47fa05e841b0841f09878e
    )
    fetch_dep(qpdf
        https://github.com/qpdf/qpdf/releases/download/v12.4.2/qpdf-12.4.2.tar.gz
        8a58af5b6141319287c1883bec8bd1bd545b7567b7fc5e6ce5d25a1c85f36397
    )

    set(all_libs "")
    # Build universal libraries on macOS
    if(APPLE AND CMAKE_OSX_ARCHITECTURES)
        # Build all architectures
        foreach(ARCH IN LISTS CMAKE_OSX_ARCHITECTURES)
            build_dependencies(${ARCH} ${DEPS_PREFIX_DIR}/${ARCH})
        endforeach()

        foreach(lib IN LISTS LIBS)
            # All per-arch libraries for ${lib}
            set(lib_libs "")
            set(lib_targets "")
            foreach(arch IN LISTS CMAKE_OSX_ARCHITECTURES)
                list(APPEND lib_libs ${${lib}-lib-${arch}})
                list(APPEND lib_targets ${lib}-build-${arch})
            endforeach()
            # Build the universal lib
            set(${lib}-lib ${DEPS_PREFIX_DIR}/lib/${${lib}-libfile})
            add_custom_command(
                OUTPUT ${${lib}-lib}
                COMMAND lipo -create ${lib_libs} -output ${${lib}-lib}
                DEPENDS
                    ${lib_libs}
                    # Also depend on the targets, otherwise make complains because it cannot find the file targets
                    ${lib_targets}
            )
            add_custom_target(${lib}-build
                ALL
                DEPENDS ${${lib}-lib}
            )
            list(APPEND all_libs ${${lib}-lib})
        endforeach()

        # Copy all headers from the first architecture to the prefix
        # XXX: This assumes that headers don't differ per architecture
        list(GET CMAKE_OSX_ARCHITECTURES 0 first_arch)
        add_custom_target(deps-headers
            ALL
            DEPENDS ${all_libs}
            COMMAND
                ${CMAKE_COMMAND} -E copy_directory
                    ${DEPS_PREFIX_DIR}/${first_arch}/include
                    ${DEPS_PREFIX_DIR}/include
        )
        set(DEPS_TARGET deps-headers)
    else()
        set(DEPS_TARGET "")
        build_dependencies("" ${DEPS_PREFIX_DIR})

        foreach(lib IN LISTS LIBS)
            list(APPEND all_libs ${${lib}-lib})
        endforeach()
    endif()

    add_library(zlib-ng STATIC IMPORTED)
    add_dependencies(zlib-ng z-build ${DEPS_TARGET})
    set_target_properties(zlib-ng PROPERTIES
        IMPORTED_LOCATION ${z-lib}
    )

    add_library(libjpeg-turbo STATIC IMPORTED)
    add_dependencies(libjpeg-turbo jpeg-build ${DEPS_TARGET})
    set_target_properties(libjpeg-turbo PROPERTIES
        IMPORTED_LOCATION ${jpeg-lib}
    )

    add_library(qpdf::libqpdf STATIC IMPORTED)
    add_dependencies(qpdf::libqpdf qpdf-build ${DEPS_TARGET})
    set_target_properties(qpdf::libqpdf PROPERTIES
        IMPORTED_LOCATION ${qpdf-lib}
        INTERFACE_INCLUDE_DIRECTORIES ${DEPS_PREFIX_DIR}/include
        INTERFACE_LINK_LIBRARIES "libjpeg-turbo;zlib-ng"
    )

    install(FILES ${all_libs}
        DESTINATION lib
    )
endif()
