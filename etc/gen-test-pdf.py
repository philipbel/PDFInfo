#!/usr/bin/env python3

import os
import sys
from pathlib import Path

import pymupdf as mu  # PyMuPDF

SELF_DIR = Path(__file__).parent.resolve()
OUT_DIR = (SELF_DIR / "../Tests/test-pdfs/").resolve()

PLEX_TTF = SELF_DIR / "IBMPlexSans-Regular.ttf"  # TrueType outlines -> CIDFontType2
PLEX_OTF = SELF_DIR / "IBMPlexSans-Regular.otf"  # CFF outlines      -> CIDFontType0

TEXT = "The quick brown fox jumps over the lazy dog 0123456789"


def _page(doc: mu.Document) -> mu.Page:
    p = doc.new_page(width=612, height=792)  # US Letter in points
    return p


def base14_not_embedded(path: Path):
    """Helvetica base-14. Not embedded, no descriptor.
    Expect: embedded=False, subset=False, subtype=Type1."""
    doc = mu.open()
    p = _page(doc)
    p.insert_text(
        (72, 72), "base-14 Helvetica (not embedded)", fontname="helv", fontsize=14
    )
    p.insert_text((72, 96), TEXT, fontname="helv", fontsize=14)
    doc.save(path)
    doc.close()


def cid_type2_embedded(path: Path):
    """Embed a TrueType-outline font -> Type0 / CIDFontType2, subset.
    Expect: embedded=True, subset=True, subtype resolves to CIDFontType2."""
    doc = mu.open()
    p = _page(doc)
    p.insert_font(fontname="PlexTTF", fontfile=PLEX_TTF)
    p.insert_text(
        (72, 72), "embedded Type0 / CIDFontType2", fontname="PlexTTF", fontsize=14
    )
    p.insert_text((72, 96), TEXT, fontname="PlexTTF", fontsize=14)
    doc.subset_fonts()
    doc.save(path, garbage=4, deflate=True)  # garbage=4 subsets/cleans
    doc.close()


def cid_type0_embedded(path: Path):
    """Embed a CFF-outline (.otf) font -> Type0 / CIDFontType0, subset.
    Expect: embedded=True, subset=True, subtype resolves to CIDFontType0."""
    doc = mu.open()
    p = _page(doc)
    p.insert_font(fontname="PlexOTF", fontfile=PLEX_OTF)
    p.insert_text(
        (72, 72), "embedded Type0 / CIDFontType0", fontname="PlexOTF", fontsize=14
    )
    p.insert_text((72, 96), TEXT, fontname="PlexOTF", fontsize=14)
    doc.subset_fonts()
    doc.save(path, garbage=4, deflate=True)
    doc.close()


def multi_font(path: Path):
    """Multiple fonts in one doc, incl. a base-14 and an embedded one.
    Exercises dedup and mixed classification in a single file."""
    doc = mu.open()
    p = _page(doc)
    p.insert_font(fontname="PlexTTF", fontfile=PLEX_TTF)
    p.insert_text((72, 72), "Helvetica base-14", fontname="helv", fontsize=14)
    p.insert_text((72, 96), "Times base-14", fontname="tiro", fontsize=14)
    p.insert_text((72, 120), "embedded Plex", fontname="PlexTTF", fontsize=14)
    doc.save(path, garbage=4, deflate=True)
    doc.close()


def with_metadata(path: Path):
    """Populated Info dict. Exercises metadata parse + display order."""
    doc = mu.open()
    p = _page(doc)
    p.insert_text((72, 72), "has metadata", fontname="helv", fontsize=14)
    doc.set_metadata(
        {
            "title": "Fixture Title",
            "author": "Phil",
            "subject": "Font inspector fixture",
            "creator": "gen-test-pdf.py",
            "producer": "PyMuPDF",
        }
    )
    doc.save(path)
    doc.close()


def encrypted(path: Path):
    """Password-protected. Tests behaviour on an encrypted file."""
    doc = mu.open()
    p = _page(doc)
    p.insert_text((72, 72), "encrypted", fontname="helv", fontsize=14)
    perm = int(mu.PDF_PERM_ACCESSIBILITY | mu.PDF_PERM_PRINT)
    doc.save(
        path,
        encryption=mu.PDF_ENCRYPT_AES_256,
        owner_pw="owner",
        user_pw="user",
        permissions=perm,
    )
    doc.close()


def malformed(path: Path):
    """Truncated file: valid header, cut body. CGPDFDocument should fail to
    open -> your init throws. Confirms no crash. (Hand-written, not via fitz.)"""
    with open(path, "wb") as f:
        f.write(b"%PDF-1.4\n")
        f.write(b"1 0 obj<< /Type /Catalog >>endobj\n")
        f.write(b"%%truncated before xref")


def verify(dir_: Path):
    """Print the actual font subtypes in each generated PDF so you can
    confirm coverage before wiring up tests. Skips the malformed one."""
    print("\n--- verification: actual fonts per fixture ---")
    for name in sorted(os.listdir(dir_)):
        if not name.endswith(".pdf"):
            continue
        path = os.path.join(dir_, name)
        try:
            doc = mu.open(path)
            if doc.needs_pass:
                doc.authenticate("user")
            seen = set()
            for pno in range(doc.page_count):
                for f in doc.get_page_fonts(pno):
                    # f = (xref, ext, type, basefont, name, encoding)
                    seen.add((f[3], f[2], f[1]))
            print(f"\n{name}:")
            for base_font, f_type, ext in sorted(seen):
                print(f"    {base_font:<28} type={f_type:<14} ext={ext}")
            doc.close()
        except Exception as e:
            print(f"\n{name}: could not open ({e})")


def main():
    for fp in (PLEX_TTF, PLEX_OTF):
        if not os.path.exists(fp):
            print(
                f"missing font: {fp}",
                file=sys.stderr,
            )
            sys.exit(1)

    os.makedirs(OUT_DIR, exist_ok=True)

    base14_not_embedded(OUT_DIR / "base14_helvetica_not_embedded.pdf")
    cid_type2_embedded(OUT_DIR / "type0_cid_font_type2_embedded_subset.pdf")
    cid_type0_embedded(OUT_DIR / "type0_cid_font_type0_embedded_subset.pdf")
    multi_font(OUT_DIR / "multi_font_mixed.pdf")
    with_metadata(OUT_DIR / "metadata_populated.pdf")
    encrypted(OUT_DIR / "encrypted.pdf")
    malformed(OUT_DIR / "malformed_truncated.pdf")

    print(f"Fixtures written to {OUT_DIR}")
    verify(OUT_DIR)


if __name__ == "__main__":
    main()
