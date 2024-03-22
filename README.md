pdf-tricks.el
=============

This file contains some handy functions I use when working with pdf-files:

  * A crude double side layout can be achieved with M-x
    my-pdf-view-double-scroll-horizontal-view-up and M-x
    my-pdf-view-double-scroll-horizontal-view (open two windows,
    offset one by one page, and then use these functions, here bound
    to y and x)
    * Text extraction with pdftotext (M-x pdf-page-to-text and
      pdf-buffer-to-text, both using poppler)
    * OCR text extraction (pdf-page-ocr, using tesseract) Adapt for
      the language files you have installed.
    * Printing function of only a subset of the pages (buggy)
    * Going to a page with an offset (nothing is worse than to keep
      calculating the offset between the page numbers in the scan and
      the ones in the pdf. Supports double-page-scans, too.

To install these, add a directory beneath your .emacs.d folder to your
load-path, copy the file in there and then require the package. E.g.:

	mkdir ~/.emacs.d/elisp
	cp pdf-tricks.el ~/.emacs.d/elisp/

Add to your .emacs or init.el:

	(add-to-list 'load-path (expand-file-name "~/.emacs.d/elisp"))
	(require 'pdf-tricks)
	
