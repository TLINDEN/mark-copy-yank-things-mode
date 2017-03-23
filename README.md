#### Usage

MCYT  minor mode  provides  convenience functions  and wrappers  to
mark, copy and yank various things with just one key chord. In copy
and yank mode the thing in  question will be highlighted shortly as
visual feedback. This can be turned off.

Copied text will  be stripped of leading  and trailing whitespaces,
fontification and other text properties will be removed. This might
change in a future version.

The MCYT  mode has  3 sub  mode key maps  for copying,  yanking and
marking things. Each sub map has it's own prefix key:

    C-c c        copy things prefix
    C-c y        yank things prefix
    C-c m        mark things prefix

COPY commands (keymap: mcyt-copy-map):

    C-c c w      mcyt-copy-word 
    C-c c q      mcyt-copy-quote 
    C-c c k      mcyt-copy-parens 
    C-c c l      mcyt-copy-line 
    C-c c p      mcyt-copy-paragraph 
    C-c c f      mcyt-copy-defun 
    C-c c u      mcyt-copy-url 
    C-c c e      mcyt-copy-email 
    C-c c c      mcyt-copy-comment-block 
    C-c c a      mcyt-copy-buffer 
    C-c c i      mcyt-copy-ip 
    C-c c s      mcyt-copy-sexp

COPY & YANK commands (keymap: mcyt-yank-map):

    C-c c y y    mcyt-copy-and-yank-line
    C-c c y l    mcyt-copy-and-yank-line
    C-c c y p    mcyt-copy-and-yank-paragraph
    C-c c y f    mcyt-copy-and-yank-defun
    C-c c y a    mcyt-copy-and-yank-buffer
    C-c c y w    mcyt-copy-and-yank-word
    C-c c y i    mcyt-copy-and-yank-ip
    C-c c y c    mcyt-copy-and-yank-comment

MARK commands (keymap: mcyt-mark-map):

    C-c c a a    mcyt-mark-buffer 
    C-c c a w    mcyt-mark-word 
    C-c c a f    mcyt-mark-defun 
    C-c c a p    mcyt-mark-paragraph 
    C-c c a l    mcyt-mark-line 
    C-c c a u    mcyt-mark-url 
    C-c c a e    mcyt-mark-email 
    C-c c a s    mcyt-mark-sexp 
    C-c c a c    mcyt-mark-comment-block 
    C-c c a i    mcyt-mark-ip 

Please note,  the commands  mcyt-copy-sexp and  mcyt-mark-sexp only
work  if  expand-region  is  installed.   You  can  find  it  here:
https://github.com/magnars/expand-region.el.

#### Install:

To use, save mark-copy-yank-things-mode.el to a directory in your load-path.

Add something like this to your config:

    (require 'mark-copy-yank-things-mode)
    (add-hook 'text-mode-hook 'mark-copy-yank-things-mode)

or load it manually, when needed:

    M-x mark-copy-yank-things-mode

However, it's also possible to enable MCYT globally:

    (mark-copy-yank-things-global-mode)

#### Customize

To turn off short blinking of copied and yanked things (visual feedback):

    (setq mark-copy-yank-things-enable-blinking nil)

Of course the mark commands do highlight anyway.

You can also customize the various prefix keys defined for this mode:

    (define-key mark-copy-yank-things-mode-map (kbd "C-c c") 'mcyt-copy-map)
    (define-key mark-copy-yank-things-mode-map (kbd "C-c y") 'mcyt-yank-map)
    (define-key mark-copy-yank-things-mode-map (kbd "C-c m") 'mcyt-mark-map)

You may also directly customize the key bindings, e.g:

    (define-key mcyt-copy-map (kbd "l") 'mcyt-copy-line)
    (define-key mcyt-yank-map (kbd "l") 'mcyt-yank-line)
    (define-key mcyt-mark-map (kbd "l") 'mcyt-mark-line)

#### Reporting Bugs:

Open   https://github.com/tlinden/mark-copy-yank-things/issues  and
file a new issue.
