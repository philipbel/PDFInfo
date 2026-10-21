# Contributing

## Requirements


### macOS (AppKit) Requirements

1. macOS 14 Sonoma or later, Intel or Apple Silicon.
2. Xcode
3. uv (optional, for generating test PDF files):
   ```
   brew install uv
   ```
4. CMake and Ninja:
   ```
   brew install cmake ninja
   ```
5. For making releases:

   5.1. GitHub:
     ```
     brew install gh
     ```

   5.2 create-dmg:
    ```
    brew install create-dmg
    ```

Tested on macOS 27 Golden Gate with Apple Silicon. Please file an
[issue](https://github.com/philipbel/PDFInfo/issues/new/choose) if the app
doesn't work for you.


### macOS (GTK) Requirements

Note: The GTK version on macOS is only useful for development. In addition to the requirements listed in
[macOS](#macos-appkit-requirements), you will also need:

1. Rust, for example via rustup:
   ```
   brew install rustup
   ```

2. GTK4 + libadwaita:
   ```
   brew install gtk4 libadwaita adwaita-icon-theme
   ```

3. pkg-config:
   ```
   brew install pkg-config
   ```

4. libclang (via LLVM)
   ```
   brew install llvm
   ```

5. gettext
   ```
   brew install gettext
   ```

### Linux Requirements

On Linux, the following packages are needed:

1. Rust, for example, via rustup
   - NixOS package: `rustup`
2. C and C++ compilers (with C++20 support), either Clang or GCC.
   - NixOS packages: `clang` or `gcc`
3. pkg-config
   - NixOS package: `pkg-config`
4. libclang
   - NixOS package: `libclang`
5. GTK4 and libadwaita.
   - NixOS packages:
     - `glib.dev`
     - `cairo.dev`
     - `harfbuzz.dev`
     - `gdk-pixbuf.dev`
     - `graphene.dev`
     - `pango.dev`
     - `vulkan-loader.dev`
     - `freetype.dev`
     - `gtk4.dev`
     - `libadwaita.dev`
6. Fontconfig
   - NixOS package: `fontconfig.dev`
7. Ninja and CMake
   - NixOS packages: `ninja`, `cmake`
8. GitHub CLI (optional, for making GitHub releases)
   - NixOS package: `github-cli`
9. uv (optional, for generating test PDFs)
   - NixOS package: `uv`
10. gettext
   - NixOS package: `gettext`

On NixOS, you need `LIBCLANG_PATH` and `PKG_CONFIG_PATH`. For example:

```nix
  environment.variables = {
    LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
  };
  environment.profileRelativeSessionVariables = {
    PKG_CONFIG_PATH = [
      "/lib/pkgconfig"
      "/share/pkgconfig"
    ];
  };
```

### Windows Requirements

1. Rust, for example using rustup via winget:
   ```
   winget install Rustlang.Rustup
   ```
2. Microsoft's C++ compiler
   ```
   winget install Microsoft.VisualStudio.BuildTools
   ```
   Once installed, launch the Visual Studio Installer, go to Modify, and install "Desktop development with C++".

3. LLVM (for bindgen)
   ```
   winget install LLVM.LLVM
   ```

4. Enable running scripts:
   ```
   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
   ```

5. Install uv (optional, for generating test PDFs):
   ```
   winget install --id=astral-sh.uv -e
   ```
   Create an environment:
   ```
   uv venv --python 3.14
   ```
   Activate the environment:
   ```
   .venv\Scripts\activate
   ```
   Install Python dependencies
   ```
   uv sync
   ```


## Building

### Building on macOS (AppKit)

1. Make sure you have the [prerequisites](#macos-appkit-requirements).
2. Run `etc/build.sh` to build the C/C++ components that the Swift app uses.
3. Open Xcode and build the `PDF Info—Debug` or `PDF Info—Release` scheme.
   
   Alternatively, from the command line:
   ```
   xcodebuild \
    -project PDFInfo.xcodeproj \
    -scheme "PDF Info—Release" \
    -configuration "Release" \
    -destination "generic/platform=macOS" \
    clean build
    ```

### Building on Linux/macOS (GTK)

1. If not building the AppKit version, set up your Rust toolchain:

   ```
   rustup default stable
   ```

   Optionally (if using `rustup`), set up `rustfmt` and `clippy`:
   - ```rustup toolchain install nightly --component rustfmt```
   - ```rustup component add clippy``` 
2. Create a Python virtual environment:
   ```
   uv venv --python 3.14
   ```
3. Activate it
   ```
   source .venv/bin/activate
   ```
4. Install Python dependencies
   ```
   uv sync
   ```
5. Build external dependencies (installed into `build/prefix/`):
   ```
   ./etc/make-deps.py
   ```


### Building on Windows

1. Open a Visual Studio Devtools shell.
2. Run `build.ps1`
