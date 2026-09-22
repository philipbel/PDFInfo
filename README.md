# PDF Info

PDF Info is a small, native macOS app for inspecting PDF fonts and metadata.

It allows you to preview the fonts (if they're installed) by pressing Space or
double clicking.

<img
  src="etc/screenshots/quick-look.png"
  alt="Quick look preview of a font"
  style="width: 600px; height=auto">

<img
  src="etc/screenshots/font-preview.png"
  alt="PDF Info showing a font preview"
  style="width: 600px; height=auto">


The app also installs a service for PDF files that shows in Finder's "Services"
menu and in the Finder context menu:

<img
  src="etc/screenshots/Finder-Services.png"
  alt="Finder Services for PDF files"
  style="width: 400px; height=auto">
<img
  src="etc/screenshots/Finder-Action.png"
  alt="Finder context menu for PDF files"
  style="width: 200px; height=auto">

## Installation

1. From GitHub: you can download a disk image (`.dmg` file) with the latest
   version from [GitHub](https://github.com/philipbel/PDFInfo/releases).
2. To install via Homebrew, first add the [philipbel/tap](https://github.com/philipbel/homebrew-tap) tap
   ```bash
   brew tap philipbel/tap
   brew trust philipbel/tap
   ```

   Then install the cask:
   ```bash
   brew install --cask pdfinfo
   ```
