;;; mcyt.el --- mark, copy, yank things

;; Copyright (C) 2017, T.v.Dein <tlinden@cpan.org>

;; This file is NOT part of Emacs.

;; This  program is  free  software; you  can  redistribute it  and/or
;; modify it  under the  terms of  the GNU  General Public  License as
;; published by the Free Software  Foundation; either version 2 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT  ANY  WARRANTY;  without   even  the  implied  warranty  of
;; MERCHANTABILITY or FITNESS  FOR A PARTICULAR PURPOSE.   See the GNU
;; General Public License for more details.

;; You should have  received a copy of the GNU  General Public License
;; along  with  this program;  if  not,  write  to the  Free  Software
;; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
;; USA

;; Version: 0.01
;; Author: T.v.Dein <tlinden@cpan.org>
;; Keywords: copy yank mark things
;; URL: https://github.com/tlinden/mark-copy-yank-things
;; License: GNU General Public License >= 2

;;; Commentary:
;;;; Usage

;; MCYT  minor mode  provides  convenience functions  and wrappers  to
;; mark, copy and yank various things with just one key chord. In copy
;; and yank mode the thing in  question will be highlighted shortly as
;; visual feedback. This can be turned off.

;; Copied text will  be stripped of leading  and trailing whitespaces,
;; fontification and other text properties will be removed. This might
;; change in a future version.

;; The MCYT  mode has  3 sub  mode key maps  for copying,  yanking and
;; marking things. Each sub map has it's own prefix key:

;;     C-c c        copy things prefix
;;     C-c y        yank things prefix
;;     C-c m        mark things prefix

;; COPY commands (keymap: mcyt-copy-map):
;;     C-c c w      mcyt-copy-word 
;;     C-c c q      mcyt-copy-quote 
;;     C-c c k      mcyt-copy-parens 
;;     C-c c l      mcyt-copy-line 
;;     C-c c p      mcyt-copy-paragraph 
;;     C-c c f      mcyt-copy-defun 
;;     C-c c u      mcyt-copy-url 
;;     C-c c e      mcyt-copy-email 
;;     C-c c c      mcyt-copy-comment-block 
;;     C-c c a      mcyt-copy-buffer 
;;     C-c c i      mcyt-copy-ip 
;;     C-c c s      mcyt-copy-sexp

;; COPY & YANK commands (keymap: mcyt-yank-map):
;;     C-c c y y    mcyt-copy-and-yank-line
;;     C-c c y l    mcyt-copy-and-yank-line
;;     C-c c y p    mcyt-copy-and-yank-paragraph
;;     C-c c y f    mcyt-copy-and-yank-defun
;;     C-c c y a    mcyt-copy-and-yank-buffer
;;     C-c c y w    mcyt-copy-and-yank-word
;;     C-c c y i    mcyt-copy-and-yank-ip
;;     C-c c y c    mcyt-copy-and-yank-comment

;; MARK commands (keymap: mcyt-mark-map):
;;     C-c c a a    mcyt-mark-buffer 
;;     C-c c a w    mcyt-mark-word 
;;     C-c c a f    mcyt-mark-defun 
;;     C-c c a p    mcyt-mark-paragraph 
;;     C-c c a l    mcyt-mark-line 
;;     C-c c a u    mcyt-mark-url 
;;     C-c c a e    mcyt-mark-email 
;;     C-c c a s    mcyt-mark-sexp 
;;     C-c c a c    mcyt-mark-comment-block 
;;     C-c c a i    mcyt-mark-ip 

;; Please note,  the commands  mcyt-copy-sexp and  mcyt-mark-sexp only
;; work  if  expand-region  is  installed.   You  can  find  it  here:
;; https://github.com/magnars/expand-region.el.

;;;; Install:

;; To use, save mcyt.el to a directory in your load-path.

;; Add something like this to your config:

;;    (require 'mark-copy-yank-things-mode)
;;    (add-hook 'text-mode-hook 'mark-copy-yank-things-mode)

;; or load it manually, when needed:

;;    M-x mark-copy-yank-things-mode

;; However, it's also possible to enable MCYT globally:

;;    (mark-copy-yank-things-global-mode)

;;;; Customize

;; To turn off short blinking of copied and yanked things (visual feedback):

;;     (setq mark-copy-yank-things-enable-blinking nil)

;; Of course the mark commands do highlight anyway.

;; You can also customize the various prefix keys defined for this mode:

;;    (define-key mark-copy-yank-things-mode-map (kbd "C-c c") 'mcyt-copy-map)
;;    (define-key mark-copy-yank-things-mode-map (kbd "C-c y") 'mcyt-yank-map)
;;    (define-key mark-copy-yank-things-mode-map (kbd "C-c m") 'mcyt-mark-map)

;; You may also directly customize the key bindings, e.g:

;;    (define-key mcyt-copy-map (kbd "l") 'mcyt-copy-line)
;;    (define-key mcyt-yank-map (kbd "l") 'mcyt-yank-line)
;;    (define-key mcyt-mark-map (kbd "l") 'mcyt-mark-line)

;;;; Reporting Bugs:

;; Open   https://github.com/tlinden/mark-copy-yank-things/issues  and
;; file a new issue
;;; Code
;;;; Dependencies

(require 'thingatpt)

;; optional: expand-region

;;;; Consts and Defs

(defconst mark-copy-yank-things-mode-version "0.01" "Mark-Copy-Yank-Things Mode version.")

(defgroup mark-copy-yank-things-mode nil
  "Kill first, ask later - an emacs mode for killing things quickly"
  :group 'extensions
  :group 'tools
  :link '(url-link :tag "Repository" "https://github.com/tlinden/mark-copy-yank-things"))

(defvar mark-copy-yank-things-mode-map (make-sparse-keymap)
  "Keymap for the MCYT minor mode.")

;;;; Customizables

(defcustom mark-copy-yank-things-blink-time 0.2
  "How long should mark-copy-yank-things highlight a region,
in seconds, specify milliseconds like this: 0.1"
  :group 'mark-copy-yank-things-mode)

(defcustom mark-copy-yank-things-enable-blinking t
  "If set to true (default) highlight the deleted text shortly
for 'mark-copy-yank-things-blink-time seconds. Set to nil to disable the feature"
  :group 'mark-copy-yank-things-mode)

;;;; Internal Functions
;;;;; Helpers

(defun mcyt--blink(begin end)
  "blink a region. used for copy and delete"
  (interactive)
  (let* ((rh (make-overlay begin end)))
    (progn
      (overlay-put rh 'face '(:background "DodgerBlue" :foreground "White"))
      (sit-for mark-copy-yank-things-blink-time t)
      (delete-overlay rh))))

(defun mcyt--get-point (symbol &optional arg)
  "Return point at symbol"
  (save-excursion
    (funcall symbol arg)
    (point)))

(defun mcyt--copy-thing (begin-of-thing end-of-thing &optional arg)
  "Copy thing between beg & end into kill ring.
Remove leading and trailing whitespace while we're at it.
Also, remove whitespace before column, if any.
Also, font-lock will be removed, if any."
  (save-excursion
    (let* ((beg (mcyt--get-point begin-of-thing 1))
           (end (mcyt--get-point end-of-thing arg)))
      (progn
        (copy-region-as-kill beg end)
        (with-temp-buffer
          (yank)
          (goto-char 1)
          (while (looking-at "[ \t\n\r]")
            (delete-char 1))
          (delete-trailing-whitespace)
          (delete-whitespace-rectangle (point-min) (point-max)) ;; del column \s, hehe
          (font-lock-unfontify-buffer) ;; reset font lock
          (kill-region (point-min) (point-max))
          )))))

(defun mcyt--blink-and-copy-thing (begin end &optional arg)
  "General wrapper for all copy[+yank] functions. Highlights
the region BEGIN to END for mark-copy-yank-things-blink-time
seconds, then copies the stuff in between into the kill-ring."
  (let ((name (car (last (split-string (symbol-name begin) "-")))))
    (if (eq t mark-copy-yank-things-enable-blinking)
        (mcyt--blink (mcyt--get-point begin 1) (mcyt--get-point end 1)))
    (mcyt--copy-thing begin end arg)
    (message (format "%s at point copied" name))))

(defun mcyt--space-p ()
  "little helper, just returns true if current char
at point is a whitespace"
  (interactive)
  (let ((c (char-after nil)))
      (or (eq 32 c) (eq 9 c))))

(defun mcyt--comment-p (pos)
  "Check whether the code at POS is comment by comparing font face."
  (interactive)
  (let* ((fontfaces (get-text-property pos 'face)))
    (if (not (listp fontfaces))
        (setf fontfaces (list fontfaces)))
    (delq nil
          (mapcar #'(lambda (f)
                      (or (eq f 'font-lock-comment-face)
                          (eq f 'font-lock-comment-delimiter-face)))
                  fontfaces))))

;;;;; Beginning- and End-of-things

(defun mcyt-beginning-of-comment-block ()
  "Move point to the beginning of a comment block"
  (interactive)
  (let ((isc t)
        (ok (point)))
    (while (and (not (bobp)) (eq t isc))
      ;; if char behind is still a comment, go there
      ;; if we're already on the first comment char on current line, go up
      (if (mcyt--comment-p (- (point) 1))
          (backward-char 1)
        (previous-line))
      ;; now, if we're not on a comment anymore,
      ;; go back to last recorded commentchar and break the loop
      (if (mcyt--comment-p (point))
          (setq ok (point))
        (goto-char ok)
        (setq isc nil)))))

(defun mcyt-end-of-comment-block ()
  "Move point to the end of a comment block, return column
of widest comment line."
  (interactive)
  (let ((isc t)
        (col (current-column))
        (ok (point)))
    (while (eq isc t)
      ;; if char in front is still a comment, go there
      ;; if not (e.g. because forward-char leads to next line)
      ;; go one line down
      (if (mcyt--comment-p (+ (point) 1))
          (forward-char 1)
        (next-line))
      ;; now, if we're not on a comment anymore, go back to the last
      ;; recorded comment char and break the loop
      (if (mcyt--comment-p (point))
          (progn
            (setq ok (point))
            (if (> (current-column) col)
                (setq col (current-column))))
        (goto-char ok)
         (setq isc nil)))
    col))

(defun mcyt-beginning-of-quote(&optional arg)
  "return position of begin of quote"
  (re-search-backward "\"" (line-beginning-position) 3 1)
  (if (looking-at "\"")  (goto-char (+ (point) 1)) ))

(defun mcyt-end-of-quote(&optional arg)
  "return position of end of quote"
  (re-search-forward "\"" (line-end-position) 3 arg)
  (if (looking-back "\"") (goto-char (- (point) 1)) ))

(defun mcyt-beginning-of-parenthesis(&optional arg)
  "return position of opening parens"
  (re-search-backward "[[<(?]" (line-beginning-position) 3 1)
  (if (looking-at "[[<(?]")  (goto-char (+ (point) 1)) ))

(defun mcyt-end-of-parenthesis(&optional arg)
  "return position of closing parens"
  (re-search-forward "[]>)?]" (line-end-position) 3 arg)
  (if (looking-back "[]>)?]") (goto-char (- (point) 1)) ))

(defun mcyt-beginning-of-ip (&optional arg)
  "goto begin of ip address"
  (interactive)
    (while (looking-at "[0-9\.\/]")
      (backward-char 1))
    (forward-char 1))

(defun mcyt-end-of-ip (&optional arg)
  "goto end of ip address"
  (interactive)
  (while (looking-at "[0-9\.\/]")
    (forward-char 1)))

;; We use these for word finding, since the built-in
;; word functions do not include -_. which is annoying
(defun mcyt-beginning-of-symbol (&optional arg)
  (interactive)
  (backward-word)
  (while (looking-back "[-_\.]")
    (backward-word)))

(defun mcyt-end-of-symbol (&optional arg)
  (interactive)
  (forward-word)
  (while (looking-at "[-_\.]")
    (forward-word)))


;;;;; Prefix-Map Loader and Key Bindings

(defun mcyt--load-prefix-maps ()
    (define-prefix-command 'mcyt-copy-map)
    (define-prefix-command 'mcyt-yank-map)
    (define-prefix-command 'mcyt-mark-map)

    (define-key mark-copy-yank-things-mode-map (kbd "C-c c") 'mcyt-copy-map)
    (define-key mark-copy-yank-things-mode-map (kbd "C-c y") 'mcyt-yank-map)
    (define-key mark-copy-yank-things-mode-map (kbd "C-c m") 'mcyt-mark-map)

    ;; "speaking" bindings CTRL-[c]opy [w]ord, etc...
    (define-key mcyt-copy-map (kbd "w") 'mcyt-copy-word)
    (define-key mcyt-copy-map (kbd "q") 'mcyt-copy-quote)
    (define-key mcyt-copy-map (kbd "k") 'mcyt-copy-parens)
    (define-key mcyt-copy-map (kbd "l") 'mcyt-copy-line)
    (define-key mcyt-copy-map (kbd "p") 'mcyt-copy-paragraph)
    (define-key mcyt-copy-map (kbd "f") 'mcyt-copy-defun)
    (define-key mcyt-copy-map (kbd "u") 'mcyt-copy-url)
    (define-key mcyt-copy-map (kbd "e") 'mcyt-copy-email)
    (define-key mcyt-copy-map (kbd "c") 'mcyt-copy-comment-block)
    (define-key mcyt-copy-map (kbd "a") 'mcyt-copy-buffer)
    (define-key mcyt-copy-map (kbd "i") 'mcyt-copy-ip)
    (define-key mcyt-copy-map (kbd "s") 'mcyt-copy-sexp)


    ;; CTRL-[c]copy-and-[y]ank [w]word, etc...
    (define-key mcyt-yank-map (kbd "y") 'mcyt-copy-and-yank-line)
    (define-key mcyt-yank-map (kbd "l") 'mcyt-copy-and-yank-line)
    (define-key mcyt-yank-map (kbd "p") 'mcyt-copy-and-yank-paragraph)
    (define-key mcyt-yank-map (kbd "f") 'mcyt-copy-and-yank-defun)
    (define-key mcyt-yank-map (kbd "a") 'mcyt-copy-and-yank-buffer)
    (define-key mcyt-yank-map (kbd "w") 'mcyt-copy-and-yank-word)
    (define-key mcyt-yank-map (kbd "i") 'mcyt-copy-and-yank-ip)
    (define-key mcyt-yank-map (kbd "c") 'mcyt-copy-and-yank-comment)

    ;; M-a'rk commands
    (define-key mcyt-mark-map (kbd "a") 'mcyt-mark-buffer)
    (define-key mcyt-mark-map (kbd "w") 'mcyt-mark-word)
    (define-key mcyt-mark-map (kbd "f") 'mcyt-mark-defun)
    (define-key mcyt-mark-map (kbd "p") 'mcyt-mark-paragraph)
    (define-key mcyt-mark-map (kbd "l") 'mcyt-mark-line)
    (define-key mcyt-mark-map (kbd "u") 'mcyt-mark-url)
    (define-key mcyt-mark-map (kbd "e") 'mcyt-mark-email)
    (define-key mcyt-mark-map (kbd "s") 'mcyt-mark-sexp)
    (define-key mcyt-mark-map (kbd "c") 'mcyt-mark-comment-block)
    (define-key mcyt-mark-map (kbd "i") 'mcyt-mark-ip))
    
;;;; API Functions / Interface
;;;;; Copy

(defun mcyt-copy-comment-block ()
  "Copy a block of comments positioned AFTER actual code.

For example:

if(tor) { # anonymous
  $C-end; # disconnect
}

In this example the following text would be copied:

# anonymous
# disconnect

Also supports normal one- or multiline comments, indended or not.
"
  (interactive)
  (let ((beg 0)
        (end 0)
        (A 0)
        (B 0)
        (max 0))
    (save-excursion
      (mcyt-beginning-of-comment-block)
      (setq beg (point))
      (set-mark-command nil)
      (setq max (mcyt-end-of-comment-block))
      (unless (>= (current-column) max)
        (setq A (point))
        (while (< (current-column) max)
          (insert " "))
        (setq B (point)))
      (setq end (point))
      (rectangle-mark-mode)
      (sit-for 0.2 t)
      (copy-rectangle-as-kill beg end)
      (unless (eq A 0)
        (delete-region A B))
      (with-temp-buffer
        (yank-rectangle)
        (delete-trailing-whitespace)
        (copy-region-as-kill (point-min) (point-max))))))

(defun mcyt-copy-line (&optional arg)
  "Copy line at point into kill-ring, truncated"
  (interactive "P")
  (mcyt--blink-and-copy-thing 'beginning-of-line 'end-of-line arg))

(defun mcyt-copy-paragraph (&optional arg)
  "Copy line at point into kill-ring, truncated"
  (interactive "P")
  (mcyt--blink-and-copy-thing 'backward-paragraph 'forward-paragraph arg))

(defun mcyt-copy-quote(&optional arg)
  "Copy a quoted string at point"
  (interactive "P")
  (mcyt--blink-and-copy-thing 'mcyt-beginning-of-quote 'mcyt-end-of-quote arg))

(defun mcyt-copy-parens(&optional arg)
  "Copy a stuff inside parens at point"
  (interactive "P")
  (mcyt--blink-and-copy-thing 'mcyt-beginning-of-parenthesis 'mcyt-end-of-parenthesis arg))

(defun mcyt-copy-word (&optional arg)
  "Copy word at point into kill-ring"
  (interactive "P")
  (mcyt--blink-and-copy-thing 'mcyt-beginning-of-symbol 'mcyt-end-of-symbol arg))

(defun mcyt-copy-buffer(&optional arg)
  "Copy the whole buffer into kill-ring, as-is"
  (interactive "P") 
  (mcyt--blink (point-min) (point-max))
  (copy-region-as-kill (point-min) (point-max))
  (message "buffer copied"))

(defun mcyt-copy-defun (&optional arg)
  "Copy function at point into kill-ring"
  (interactive "P")
  (mcyt--blink-and-copy-thing 'beginning-of-defun 'end-of-defun arg))

(defun mcyt-copy-url (&optional arg)
  "Copy url or file-path at point into kill-ring"
  (interactive "P")
  (let ((beg (car (or (bounds-of-thing-at-point 'url) (bounds-of-thing-at-point 'filename))))
        (end (cdr (or (bounds-of-thing-at-point 'url) (bounds-of-thing-at-point 'filename)))))
    (mcyt--blink beg end)
    (kill-ring-save beg end)
    (message "url at point copied")))

(defun mcyt-copy-email (&optional arg)
  "Copy email at point into kill-ring"
  (interactive "P")
  (let ((beg (car (bounds-of-thing-at-point 'email)))
        (end (cdr (bounds-of-thing-at-point 'email))))
    (mcyt--blink beg end)
    (kill-ring-save beg end)
    (message "email at point copied")))

(defun mcyt-copy-sexp (&optional arg)
  "Copy sexp at point into kill-ring"
  (interactive "P")
  (if (not (fboundp 'er/mark-outside-pairs))
      (message "(mcyt-copy-sexp) not supported, install expand-region.")
    (let ((ign (er/mark-outside-pairs))
          (beg (mark))
          (end (point)))
      (deactivate-mark)
      (mcyt--blink beg end)
      (kill-ring-save beg end)
      (message "sexp at point copied"))))

(defun mcyt-copy-ip (&optional arg)
  "Copy ip address at point into kill-ring"
  (interactive "P")
  (mcyt--blink-and-copy-thing 'mcyt-beginning-of-ip 'mcyt-end-of-ip arg))

;;;;; Copy+Yank

(defun mcyt-copy-and-yank-word (&optional arg)
  "copy current word, yank it after current and place the cursor to the beginning of the copy"
  (interactive "P")
  (progn
    (mcyt-copy-word)
    (mcyt-end-of-symbol)
    (insert " ")
    (yank)))

(defun mcyt-copy-and-yank-ip (&optional arg)
  "copy current ip, yank it after current and place the cursor to the beginning of the copy"
  (interactive "P")
  (progn
    (mcyt-copy-ip)
    (mcyt-end-of-ip)
    (insert " ")
    (yank)))

(defun mcyt-copy-and-yank-line (&optional arg)
  "copy current line, yank it below and place the cursor there.
Supports numerical arguments, if present, copy current line
ARG times. Also accessible with {C-u [0-9]+ C-c y y}"
  (interactive "P")
  (message "arg: %s" (prefix-numeric-value arg))
  (loop for i
        below (prefix-numeric-value arg)
        collect (progn
                  (mcyt-copy-line)
                  (move-end-of-line nil)
                  (newline-and-indent)
                  (yank))))

(defun mcyt-copy-and-yank-paragraph(&optional arg)
  "copy current paragraph, add two newlines after current paragraph,
yank the copy below and place the cursor on the beginning of
copied paragraph"
  (interactive "P")
  (progn
    (mcyt-copy-paragraph)
    (move-end-of-line nil)
    (newline-and-indent)
    (newline-and-indent)
    (yank)
    (backward-paragraph)
    (next-line)))

(defun mcyt-copy-and-yank-defun(&optional arg)
  "copy current function, add two newlines after current function,
yank the copy below and place the cursor on the beginning of
copied defun"
  (interactive "P")
  (progn
    (mcyt-copy-defun)
    (end-of-defun)
    (newline-and-indent)
    (newline-and-indent)
    (yank)
    (beginning-of-defun)))

(defun mcyt-copy-and-yank-buffer(&optional arg)
  "copy the whole buffer and yank all of it after end-of-buffer"
  (interactive "P")
  (progn
    (mcyt-copy-buffer)
    (end-of-buffer)
    (newline)
    (yank)))

(defun mcyt-copy-and-yank-comment(&optional arg)
  "copy current comment block, add newline, yank the copy
below and place the cursor on the end of copied comment"
  (interactive "P")
  (progn
    (mcyt-copy-comment-block)
    (mcyt-end-of-comment-block)
    (newline-and-indent)
    (yank)
    (end-of-coment-block)))

;;;;; Mark

;; related, but just mark things
(defun mcyt-mark-line ()
  (interactive)
  (move-beginning-of-line nil)
  (set-mark-command nil)
  (move-end-of-line nil)
  (setq deactivate-mark nil))

(defun mcyt-mark-word()
  (interactive)
  (mcyt-beginning-of-symbol)
  (set-mark-command nil)
  (mcyt-end-of-symbol)
  (setq deactivate-mark nil))

(defun mcyt-mark-url()
  (interactive)
  (beginning-of-thing 'url)
  (set-mark-command nil)
  (end-of-thing 'url)
  (setq deactivate-mark nil))

(defun mcyt-mark-email()
  (interactive)
  (beginning-of-thing 'email)
  (set-mark-command nil)
  (end-of-thing 'email)
  (setq deactivate-mark nil))

(defun mcyt-mark-ip()
  (interactive)
  (mcyt-beginning-of-ip)
  (set-mark-command nil)
  (mcyt-end-of-ip)
  (setq deactivate-mark nil))

(defun mcyt-mark-comment-block ()
  "Same as mcyt-copy-comment-block, without the copying part."
  (interactive)
  (let ((beg 0)
        (end 0)
        (A 0)
        (B 0)
        (max 0))
    (save-excursion
      (mcyt-beginning-of-comment-block)
      (setq beg (point))
      (set-mark-command nil)
      (setq max (mcyt-end-of-comment-block))
      (unless (>= (current-column) max)
        (setq A (point))
        (while (< (current-column) max)
          (insert " "))
        (setq B (point)))
      (setq end (point))
      (rectangle-mark-mode))))

(defun mcyt-mark-buffer ()
  (interactive)
  (mark-whole-buffer))

(defun mcyt-mark-defun ()
  (interactive)
  (mark-defun))

(defun mcyt-mark-sexp ()
  (interactive)
  (if (not (fboundp 'er/mark-outside-pairs))
      (message "(mcyt-mark-sexp) not supported, install expand-region.")
    (er/mark-outside-pairs)))

(defun mcyt-mark-paragraph ()
  (interactive)
  (mark-paragraph))

;;;; Minor Mode and Key Map

;;;###autoload

;; the minor mode, can be enabled by major mode via hook or manually
(define-minor-mode mark-copy-yank-things-mode "mark, copy and yank various things"
  :lighter " Y"
  :group 'mark-copy-yank-things-mode
  (mcyt--load-prefix-maps))

;; just in case someone wants to use it globally
(define-globalized-minor-mode mark-copy-yank-things-global-mode
  mark-copy-yank-things-mode mark-copy-yank-things-mode
  :group 'mark-copy-yank-things-mode)

(provide 'mark-copy-yank-things-mode)






;;; mcyt.el ends here
