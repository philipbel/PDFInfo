#!/bin/bash

if [ ! -d "gtk" -o ! -d po ]; then
    echo "Run from teh top-level directory"
    exit 1
fi

xgettext \
  --language=Rust \
  --from-code=UTF-8 \
  --keyword=gettext \
  --keyword=gettext_f! \
  --keyword=ngettext:1,2 \
  --keyword=pgettext:1c,2 \
  --add-comments=TRANSLATORS \
  --package-name=PDFInfo \
  --output=po/pdfinfo.pot \
  $(find gtk/src -name '*.rs')
