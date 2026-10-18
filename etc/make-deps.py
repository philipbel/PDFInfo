#!/usr/bin/env python

import itertools
import os
import platform
import shlex
import shutil
import sys
from argparse import ArgumentParser
from enum import StrEnum
from pathlib import Path
from subprocess import CalledProcessError, run

SHELL = "bash"
PROG = os.path.basename(__file__)
ROOT_DIR = Path(os.path.realpath(__file__)).parent.parent
BUILD_DIR = ROOT_DIR / "build"
PREFIX_DIR = BUILD_DIR / "prefix"
EXTERN_DIR = ROOT_DIR / "extern"

MACOS_DEPLOYMENT_TARGET = "14.0"


class Platform(StrEnum):
    MACOS = "macos"
    LINUX = "linux"
    WINDOWS = "windows"


class Architecture(StrEnum):
    X86_64 = "x86_64"
    ARM64 = "arm64"


def get_platform() -> Platform:
    system = platform.system()
    match system:
        case "Darwin":
            return Platform.MACOS
        case "Linux":
            return Platform.LINUX
        case "Windows":
            return Platform.WINDOWS
        case _:
            raise ValueError(f"Unsupported platform '{system}'")


def get_architectures(for_platform: Platform) -> list[Architecture]:
    match for_platform:
        case Platform.MACOS:
            return [Architecture.ARM64, Architecture.X86_64]
        case _:
            machine = platform.machine()
            match machine:
                case "x86_64" | "AMD64":
                    return [Architecture.X86_64]
                case "arm64" | "aarch64" | "ARM64":
                    return [Architecture.ARM64]
                case _:
                    raise ValueError(f"Unsupported machine '{machine}'")


PLATFORM = get_platform()
ARCHITECTURES = get_architectures(for_platform=PLATFORM)


def _save_output(log_prefix: str, stdout: str, stderr: str):
    with open(f"{log_prefix}.stdout", "w") as fp:
        fp.write(stdout)
    with open(f"{log_prefix}.stderr", "w") as fp:
        fp.write(stderr)


def shell(*args: str, name: str, log_prefix: str, verbose: bool, dry: bool):
    cmd = shlex.join(args)
    print(f"[{name}] {cmd}")
    if dry:
        return
    try:
        result = run(
            [SHELL, "-c", cmd], capture_output=True, text=True, check=True, cwd=ROOT_DIR
        )
        _save_output(log_prefix=log_prefix, stdout=result.stdout, stderr=result.stderr)
        if verbose:
            print(f"[{name}] {cmd} finished with exit code {result.returncode}")
    except CalledProcessError as e:
        print(f"[{name}] error running {cmd}: {e}. See log files {log_prefix}")
        _save_output(log_prefix=log_prefix, stdout=e.stdout, stderr=e.stderr)
        raise ChildProcessError(f"Failed to run command {cmd}") from e


def run_cmake(
    *args: str,
    name: str,
    log_prefix: str,
    verbose: bool,
    dry: bool,
):
    # fmt: off
    shell(
        "cmake",
        *args,
        name=name,
        log_prefix=log_prefix,
        dry=dry,
        verbose=verbose,
    )
    # fmt: on


def cmake_configure(
    *args: str,
    name: str,
    target_platform: Platform,
    target_architecture: Architecture,
    src_dir: Path,
    build_dir: Path,
    prefix_dir: Path,
    dry: bool,
    verbose: bool,
):
    print(f"[{name}] Configuring")

    platform_args: list[str] = []
    if target_platform == Platform.MACOS:
        platform_args += [
            f"-DCMAKE_OSX_ARCHITECTURES={target_architecture}",
            f"-DCMAKE_OSX_DEPLOYMENT_TARGET={MACOS_DEPLOYMENT_TARGET}",
        ]
    # fmt: off
    run_cmake(
        "-S", str(src_dir),
        "-B", str(build_dir),
        "-G", "Ninja",
        f"-DCMAKE_INSTALL_PREFIX={prefix_dir}",
        "-DCMAKE_BUILD_TYPE=Release",
        f"-DCMAKE_PREFIX_PATH={prefix_dir}",
        "-DPKG_CONFIG_EXECUTABLE=/usr/bin/false", # Force no pkg-config in CMake
        *args,
        *platform_args,
        name=name,
        log_prefix=f"{build_dir}/configure.{name}",
        dry=dry,
        verbose=verbose,
    )
    # fmt: on


def cmake_build(name: str, build_dir: Path, dry: bool, verbose: bool):
    print(f"[{name}] Building")
    run_cmake(
        "--build",
        str(build_dir),
        name=name,
        log_prefix=f"{build_dir}/build.{name}",
        dry=dry,
        verbose=verbose,
    )


def cmake_install(
    name: str,
    build_dir: Path,
    target_platform: Platform,
    target_architecture: Architecture,
    dry: bool,
    verbose: bool,
):
    print(f"[{name}] Installing")
    # fmt: off
    run_cmake(
        "--install", str(build_dir),
        name=name,
        log_prefix=f"{build_dir}/install.{name}",
        dry=dry,
        verbose=verbose,
    )
    # fmt: on

    # On Linux, make lib point to lib64
    if target_platform == Platform.LINUX:
        arch_dir = PREFIX_DIR / PLATFORM / target_architecture
        lib64_dir = arch_dir / "lib64"
        lib_dir = arch_dir / "lib"
        if lib64_dir.exists() and not lib_dir.exists():
            os.symlink(lib64_dir, lib_dir)


def build_cmake_package(
    name: str,
    target_architectures: list[Architecture],
    target_platform: Platform,
    src_dir: Path,
    build_dir: Path,
    prefix_dir: Path,
    configure_args: list[str],
    verbose: bool,
    dry: bool,
):
    for architecture in target_architectures:
        lib_build_dir = build_dir / target_platform / architecture / name
        lib_prefix_dir = prefix_dir / target_platform / architecture
        if dry:
            print(f"[{name}] would make dir {lib_build_dir}")
        else:
            os.makedirs(lib_build_dir, exist_ok=True)
        print(
            f"[{name}] Building: "
            f"platform={target_platform} "
            f"architecture={architecture} "
            f"src_dir={src_dir} "
            f"prefix_dir={lib_prefix_dir} "
            f"build_dir={lib_build_dir}"
        )

        cmake_configure(
            *configure_args,
            name=name,
            target_platform=target_platform,
            target_architecture=architecture,
            src_dir=src_dir,
            build_dir=lib_build_dir,
            prefix_dir=lib_prefix_dir,
            dry=dry,
            verbose=verbose,
        )
        cmake_build(
            name=name,
            build_dir=lib_build_dir,
            dry=dry,
            verbose=verbose,
        )
        cmake_install(
            name=name,
            build_dir=lib_build_dir,
            target_platform=target_platform,
            target_architecture=architecture,
            dry=dry,
            verbose=verbose,
        )


def main(args: list[str]):
    arg_parser = ArgumentParser(prog=PROG, description="Dependency builder")
    arg_parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        default=False,
        help="print verbose messages",
    )
    arg_parser.add_argument(
        "-n",
        "--dry",
        action="store_true",
        default=False,
        help="only print what would be executed",
    )
    opts = arg_parser.parse_args(args)

    build_cmake_package(
        name="zlib-ng",
        src_dir=EXTERN_DIR / "zlib-ng",
        prefix_dir=PREFIX_DIR,
        build_dir=BUILD_DIR,
        target_platform=PLATFORM,
        target_architectures=ARCHITECTURES,
        configure_args=[
            "-DZLIB_COMPAT=ON",
            "-DBUILD_TESTING=OFF",
            "-DBUILD_SHARED_LIBS=OFF",
        ],
        dry=opts.dry,
        verbose=opts.verbose,
    )

    build_cmake_package(
        name="libjpeg-turbo",
        src_dir=EXTERN_DIR / "libjpeg-turbo",
        prefix_dir=PREFIX_DIR,
        build_dir=BUILD_DIR,
        target_platform=PLATFORM,
        target_architectures=ARCHITECTURES,
        configure_args=[
            "-DENABLE_SHARED=OFF",
            "-DENABLE_STATIC=ON",
            "-DWITH_SIMD=OFF",
            "-DWITH_TURBOJPEG=OFF",
            "-DWITH_TOOLS=OFF",
        ],
        dry=opts.dry,
        verbose=opts.verbose,
    )

    build_cmake_package(
        name="qpdf",
        src_dir=EXTERN_DIR / "qpdf",
        prefix_dir=PREFIX_DIR,
        build_dir=BUILD_DIR,
        target_platform=PLATFORM,
        target_architectures=ARCHITECTURES,
        configure_args=[
            "-DBUILD_SHARED_LIBS=OFF",
            "-DBUILD_STATIC_LIBS=ON",
            "-DUSE_IMPLICIT_CRYPTO=OFF",
            "-DREQUIRE_CRYPTO_NATIVE=ON",
            "-DSTATIC_JPEG=ON",
            "-DINSTALL_EXAMPLES=OFF",
        ],
        dry=opts.dry,
        verbose=opts.verbose,
    )

    # Make macOS universal binaries
    if PLATFORM == Platform.MACOS:
        universal_prefix_dir = PREFIX_DIR / str(PLATFORM) / "universal"
        if not opts.dry:
            os.makedirs(universal_prefix_dir / "lib", exist_ok=True)
        # Verify headers for all architectures are the same
        for arch1, arch2 in itertools.combinations(ARCHITECTURES, 2):
            try:
                shell(
                    "diff",
                    "-r",
                    str(PREFIX_DIR / PLATFORM / arch1 / "include"),
                    str(PREFIX_DIR / PLATFORM / arch2 / "include"),
                    name="diff",
                    log_prefix=f"{universal_prefix_dir}/diff-{arch1}-{arch2}",
                    verbose=opts.verbose,
                    dry=opts.dry,
                )
            except ChildProcessError as e:
                print(f"Error: headers for architectures {arch1} and {arch2} differ")
                raise ChildProcessError(
                    f"headers for architectures {arch1} and {arch2} differ"
                ) from e
        # Copy headers
        if not opts.dry:
            shutil.copytree(
                src=PREFIX_DIR / str(PLATFORM) / str(ARCHITECTURES[0]) / "include",
                dst=universal_prefix_dir / "include",
                dirs_exist_ok=True,
            )
        # Make universal binaries
        for lib in ["libz.a", "libjpeg.a", "libqpdf.a"]:
            print(f"Making universal binaries for {lib}")

            lib_paths = [
                str(PREFIX_DIR / PLATFORM / str(a) / "lib" / lib) for a in ARCHITECTURES
            ]

            shell(
                "lipo",
                "-create",
                *lib_paths,
                "-output",
                str(universal_prefix_dir / "lib" / lib),
                name="lipo",
                log_prefix=f"{universal_prefix_dir}/lipo-{lib}",
                verbose=opts.verbose,
                dry=opts.dry,
            )


if __name__ == "__main__":
    main(sys.argv[1:])
