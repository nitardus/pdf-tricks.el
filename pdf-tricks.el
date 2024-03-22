;;----------------------------------------------------------------------------------
;; FUNCTIONS FOR DOUBLE-PAGE LAYOUT
(defun my-pdf-view-double-scroll-up-or-next-page (&optional arg)
  "Scroll page up ARG lines if possible, else go to the next page.

When `pdf-view-continuous' is non-nil, scrolling upward at the
bottom edge of the page moves to the next page.  Otherwise, go to
next page only on typing SPC (ARG is nil)."
  (interactive "P")
  (if (or pdf-view-continuous (null arg))
      (let ((hscroll (window-hscroll))
            (cur-page (pdf-view-current-page))
            (win-scroll (window-vscroll nil pdf-view-have-image-mode-pixel-vscroll))
            (img-scroll (image-scroll-up arg)))
        (when (or
               ;; There is no next line for the image to scroll to
               (and img-scroll (= win-scroll img-scroll))
               ;; Workaround rounding/off-by-one issues.
               (memq pdf-view-display-size
                     '(fit-height fit-page)))
          (pdf-view-next-page 2)
          (when (/= cur-page (pdf-view-current-page))
            (image-bob)
            (image-bol 1))
          (image-set-window-hscroll hscroll)))
    (image-scroll-up arg)))

(defun my-pdf-view-double-scroll-down-or-previous-page (&optional arg)
  "Scroll page down ARG lines if possible, else go to the previous page.

When `pdf-view-continuous' is non-nil, scrolling downward at the
top edge of the page moves to the previous page.  Otherwise, go
to previous page only on typing DEL (ARG is nil)."
  (interactive "P")
  (if (or pdf-view-continuous (null arg))
      (let ((hscroll (window-hscroll))
            (cur-page (pdf-view-current-page))
            (win-scroll (window-vscroll nil pdf-view-have-image-mode-pixel-vscroll))
            (img-scroll (image-scroll-down arg)))
        (when (or
               ;; There is no previous line for the image to scroll to
               (and img-scroll (= win-scroll img-scroll))
               ;; Workaround rounding/off-by-one issues.
               (memq pdf-view-display-size
                     '(fit-height fit-page)))
          (pdf-view-previous-page 2)
          (when (/= cur-page (pdf-view-current-page))
            (image-eob)
            (image-bol 1))
          (image-set-window-hscroll hscroll)))
    (image-scroll-down arg)))

(defun my-pdf-view-double-scroll-horizontal-view ()
  (interactive)
  (my-pdf-view-double-scroll-up-or-next-page)
  (other-window 1)
  (my-pdf-view-double-scroll-up-or-next-page)
  (other-window 1))

(defun my-pdf-view-double-scroll-horizontal-view-up ()
  (interactive)
  (my-pdf-view-double-scroll-down-or-previous-page)
  (other-window 1)
  (my-pdf-view-double-scroll-down-or-previous-page)
  (other-window 1))

(add-hook 'pdf-view-mode-hook
 (lambda ()
   (local-set-key (kbd "y") 'my-pdf-view-double-scroll-horizontal-view-up)
   (local-set-key (kbd "x") 'my-pdf-view-double-scroll-horizontal-view)))


;;----------------------------------------------------------------------------------
;; FUNCTIONS FOR TEXT EXTRACTION: TEXT
;; PDF-View-to-text
(defun pdf-page-to-text (pdf-file page-number &optional layout opt)
  "A simple elisp wrapper for the pdftotext-utility
PDF-FILE: The PDF file to process.
PAGE-NUMBER: The page number to process.
LAYOUT: (optional) Controls the layout options of pdftotext.
OPT: Additional options passed through to pdftotext. See man 1 pdftotext." 
  (interactive
   (list (pdf-view-buffer-file-name)
         (pdf-view-current-page)
	 (if (y-or-n-p "Egalize Layout? ") "" "-layout")
	 (read-from-minibuffer "Additional options: ")))
  (let* ((layout (or layout ""))
	 (opt (or opt "")) 
	 (temp-text-file (format "/tmp/pdf-page-%d.txt" page-number)))
    ;; (message (format "pdftotext %s %s -f %d -l %d %s %s" layout opt page-number page-number pdf-file temp-text-file))
    (shell-command (format "pdftotext %s %s -f %d -l %d %s %s" layout opt page-number page-number (concat "\"" pdf-file "\"") temp-text-file))
    ;; (find-file-other-window temp-text-file)
    (find-file temp-text-file)
    (message "Text saved to: %s" temp-text-file)))

(defun pdf-buffer-to-text (pdf-file &optional layout opt)
  "A simple elisp wrapper for the pdftotext-utility
PDF-FILE: The PDF file to process.
PAGE-NUMBER: The page number to process.
LAYOUT: (optional) Controls the layout options of pdftotext.
OPT: Additional options passed through to pdftotext. See man 1 pdftotext." 
  (interactive
   (list (pdf-view-buffer-file-name)
	 (if (y-or-n-p "Egalize Layout? ") "" "-layout")
	 (read-from-minibuffer "Additional options: ")))
  (let* ((layout (or layout ""))
	 (opt (or opt "")) 
	 (temp-text-file (format "/tmp/pdf%s.txt" (file-name-nondirectory pdf-file))))
    (shell-command (format "pdftotext -q %s %s %s %s" layout opt (concat "\"" pdf-file "\"") temp-text-file))
    (find-file temp-text-file)
    (message "Text saved to: %s" temp-text-file)))


;;----------------------------------------------------------------------------------
;; FUNCTIONS FOR TEXT EXTRACTION: OCR

;; PDF-View-to-ocr
(defun pdf-page-ocr (pdf-file page-number &optional language columns oem)
  "OCR a specific page of a PDF file using ImageMagick and Tesseract.
PDF-FILE: The PDF file to process.
PAGE-NUMBER: The page number to process.
LANGUAGES: (optional) A comma-separated string of the languages of the text.
            Defaults to 'deu' (German). Possible languages: 'deu', 'eng', 'lat', 'grc'.
COLUMNS: (optional) The number of columns in the page. Defaults to 1.
OEM: (optional) The OCR Engine Mode to use. Defaults to 1."
  (interactive
   (list (pdf-view-buffer-file-name)
         (pdf-view-current-page)
         ;; (completing-read "Language (default 'deu'): " '("deu" "eng" "lat" "grc" "deu+eng" "deu+lat" "deu+grc" "eng+lat" "eng+grc" "lat+grc") nil t)
         (mapconcat 'identity
                    (completing-read-multiple
                     "Languages (default 'deu', comma-separated): "
                     '("deu" "deu_frak" "eng" "lat" "grc" "ell" "heb" "fra" "ita" "spa") nil t)
                    "+")
	 (read-number "Number of columns (default 1), or percentage, if > 10: " 1)
	 (read-number "OCR Engine Mode (default 1): " 1)))
  (let* ((language (or language "deu"))
	 (columns (or columns 1))
	 (oem (or oem 1))
	 (temp-image-file-no-png (format "/tmp/pdf-page-%d" page-number))
         (temp-image-file (format "/tmp/pdf-page-%d.png" page-number))
         (temp-text-file (format "/tmp/pdf-page-%d.txt" page-number))
         (imagemagick-cmd (format "convert -density 300 \"%s[%d]\" -depth 8 -strip -background white -alpha off %s"
                                  pdf-file (- page-number 1) temp-image-file))
	 (split (if (< columns 10) (/ 100 columns) columns))
         (column-split-cmd (if (< split 50)
			       (format "convert %s -crop %dx100%%+0+0 +repage %s-0.png;
                                        convert %s -gravity NorthEast -crop %dx100%%+0+0 +repage %s-1.png;
                                        convert -append %s-*.png %s"
                                        temp-image-file split temp-image-file-no-png
                                        temp-image-file (- 100 split) temp-image-file-no-png
                                        temp-image-file-no-png temp-image-file)
			     (format "convert %s -crop %dx100%% +repage %s; convert -append %s-*.png %s"
                                   temp-image-file split temp-image-file temp-image-file-no-png temp-image-file)))
	 (tesseract-cmd (format "tesseract %s %s -l %s --oem %d"
                                temp-image-file (file-name-sans-extension temp-text-file) language oem)))
    (shell-command imagemagick-cmd)
    (when (> columns 1)
      (shell-command column-split-cmd))
    (shell-command tesseract-cmd)
    (find-file-other-window temp-text-file)
    (message "OCR result saved to: %s" temp-text-file)
    (shell-command (format "rm %s-*" temp-image-file-no-png))))

;;----------------------------------------------------------------------------------
;; FUNCTIONS TO FIND THE RIGHT PAGE
(defun my-pdf-view-goto-page-arguments (page double-page &optional window)
  "Go to PAGE in PDF.
Asks additionally, if the pdf file has a single or double page
layout, and if the displayed page is the intended page. If not,
asks for the displayed page and goes to this page. It saves these
preferences for the current buffer for use of the
my-pdf-view-goto-page function."
  (interactive
   (list (if current-prefix-arg		; Taken over from pdf-view-goto-page
             (prefix-numeric-value current-prefix-arg)
	   (read-number "Page: "))
	 (progn				; Prompt for single or double page layout
	   (or				; Set my-pdf-double-page variable locally
	    (boundp 'my-pdf-double-page-layout)
	    (make-local-variable 'my-pdf-double-page-layout))
	   (setq my-pdf-double-page-layout (not (y-or-n-p "Single Page? "))))))
  (when double-page
    (setq page (+ 1 (/ page 2))))
  (pdf-view-goto-page page)
  ;; Compute the offset, if any
  (unless (y-or-n-p "Is this the indended page number? ")
    (let* ((actual-page	(read-number "corresponds to page number: ")))
      (when double-page
	(setq actual-page (+ 1 (/ actual-page 2))))
      (or			
       (boundp 'my-pdf-page-offset)
       (make-local-variable 'my-pdf-page-offset))
      (setq my-pdf-page-offset (- page actual-page)))
    (pdf-view-goto-page (+ page my-pdf-page-offset))))

(defun my-pdf-view-goto-page (page double-page offset &optional window)
  "Go to PAGE in PDF.
Asks additionally, if the pdf file has a single or double page
layout, and if the displayed page is the intended page. If not,
asks for the displayed page and goes to this page. It saves these
preferences for the current buffer for use of the
my-pdf-view-goto-page function."
  (interactive
   (list (if current-prefix-arg		; Taken over from pdf-view-goto-page
             (prefix-numeric-value current-prefix-arg)
	   (read-number "Page: "))
	 (if (boundp 'my-pdf-double-page-layout) my-pdf-double-page-layout nil)
	 (if (boundp 'my-pdf-page-offset) my-pdf-page-offset 0)))
  (when double-page
    (setq page (+ 1 (/ page 2))))
  (pdf-view-goto-page (+ page offset)))

(defun my-pdf-print-document (filename)
  "Wrapper around pdf-misc-print-document.

Enables the user to print only a subset of the document, which
then gets preprocessed by pdftk"
  (interactive
   (list (pdf-view-buffer-file-name)))
;;  (cl-check-type filename (and string (satisfies file-readable-p)))
  (if (y-or-n-p "Print the whole document? ")
      (pdf-misc-print-document filename)
    (let ((pages (read-string "Please specify the pages to be printed: "))
	  (printfile "/tmp/pdftk-print.pdf"))
      (shell-command (format "pdftk '%s' cat %s output %s" filename pages printfile))
      (pdf-misc-print-document printfile))))


(add-hook 'pdf-view-mode-hook
 (lambda ()
   (local-set-key (kbd "C-c p") 'my-pdf-print-document)
   (local-set-key (kbd "M-g M-g") 'my-pdf-view-goto-page)
   (local-set-key (kbd "M-g g") 'my-pdf-view-goto-page-arguments)))



(provide 'pdf-tricks)
