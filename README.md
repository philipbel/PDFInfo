# PDF Info

PDF Info is a small, native macOS app for inspecting PDF fonts and metadata.

<img
  src="Help/images/app.png"
  alt="Quick look preview of a font"
  style="width: 600px; height=auto">

## License

[MIT License](https://github.com/philipbel/PDFInfo/tree/master?tab=MIT-1-ov-file)


## Requirements

* macOS 14 Sonoma or later.
* Intel or Apple Silicon

Tested on macOS 27 Golden Gate with Apple Silicon. Please file an
[issue](https://github.com/philipbel/PDFInfo/issues/new/choose) if the app
doesn't work for you.


## Installation

There are two ways to install PDF Info:

1. From GitHub: download a disk image (`.dmg` file) with the latest
   version from [GitHub](https://github.com/philipbel/PDFInfo/releases).

2. Install via Homebrew:

    a) First add the [philipbel/tap](https://github.com/philipbel/homebrew-tap) tap
      ```bash
      brew tap philipbel/tap
      brew trust philipbel/tap
      ```
   b) install the cask:
      ```bash
      brew install --cask pdfinfo
      ```


## Development

Requirements:
1. Xcode
2. For generating test PDF files:
    - Python 3.14
    - uv (`brew install uv`)

3. For making releases:
    - gh (`brew install gh`)
    - create-dmg (`brew install create-dmg`)
