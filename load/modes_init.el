;; various small modes configuration

;(autoload 'gnus "gnus" "Best email client ever" t)

(require 'imenu)
(autoload 'filladapt-mode "filladapt" "Minor mode to adaptively set fill-prefix and overload filling functions" t)
(autoload 'htmlize-buffer "htmlize" "Convert buffer text and decorations to HTML" t)
(autoload 'grep "grep+" "Extensions to standard library `grep.el'" t)

(autoload 'find-tag "etags" "etags facility" t)
(setq tags-file-name (expand-file-name "~/TAGS"))

(autoload 'session-initialize "session" "Use variables, registers and buffer places across sessions" t)
(add-hook 'after-init-hook 'session-initialize)

;; dired
(setq
 dired-bind-jump nil
 dired-omit-extensions '(".pyc" ".elc"))
(autoload 'dired-jump "dired-x" "Jump to dir of current file" t)
(autoload 'dired-omit-mode "dired-x" "Omit unnecessary files in dired view" t)
(add-hook 'dired-mode-hook 'dired-omit-mode)
(eval-after-load "dired"
  '(define-key dired-mode-map (kbd "C-,") (fun-for-bind bs--show-with-configuration "dired")))

(column-number-mode 1)

;; I hate blinking
(if (fboundp 'blink-cursor-mode)
  (blink-cursor-mode -1))

;; It's rare, but annoying
(if (fboundp 'global-semantic-stickyfunc-mode)
    (global-semantic-stickyfunc-mode -1))

;; highlight marked text
(transient-mark-mode 1)
;; but work even without it
(setq mark-even-if-inactive t)

(show-paren-mode 1)

;; IDO, you are very nice
(ido-mode 1)
(setq
 ido-enable-flex-matching 1
 ido-show-dot-for-dired t
 ido-auto-merge-work-directories-length -1 ; disable auto-merging
 ido-confirm-unique-completion t)

(winner-mode 1) ;; window configuration undo/redo

(require 'uniquify)
(setq uniquify-buffer-name-style 'post-forward)

(add-hook 'isearch-mode-end-hook
          (lambda ()
            (when isearch-forward (goto-char isearch-other-end))))

;; saving place in file
(require 'saveplace)
(setq-default save-place t)
(setq save-place-file "~/.emacs.d/places/")

;; major modes

(autoload 'markdown-mode "markdown-mode" "Major mode for editing Markdown files" t)
(autoload 'wikipedia-mode "wikipedia-mode" "Major mode for editing MediaWiki files" t)
(autoload 'django-html-mode "django-html-mode" "Django HTML templates" t)
(autoload 'haskell-mode "haskell-mode" "Major mode for editing Haskell sources" t)
(autoload 'io-mode "io-mode" "Major mode for editing Io sources" t)
(autoload 'yaml-mode "yaml-mode" nil t)
(autoload 'lua-mode "lua-mode" nil t)
(load "fuel/fu" t)

(require 'whitespace)
(setq whitespace-style '(lines-tail trailing))
(set-face-attribute 'whitespace-line nil
                    :foreground 'unspecified
                    :background "yellow")

(setq hooks-with-whitespaces
      '(factor-mode-hook
        wikipedia-mode-hook
        markdown-mode-hook
        erlang-mode-hook
        haskell-mode-hook
        python-mode-hook
        lua-mode-hook))
(dolist (hook hooks-with-whitespaces) (add-hook hook 'whitespace-mode))


(setq hooks-want-short-lines
      '(markdown-mode-hook
        wikipedia-mode-hook
        rst-mode-hook))
(dolist (hook hooks-want-short-lines)
  (add-hook hook 'auto-fill-mode))

(setq auto-mode-alist
      (append
       (list
        '("\\.md\\'" . markdown-mode)
        '("\\.erl\\'" . erlang-mode)
        '("\\.hs\\'" . haskell-mode)
        '("\\.wiki\\.txt\\'" . wikipedia-mode)
        '("\\.html\\'" . django-html-mode)
        '("\\.egg\\'" . archive-mode)
        '("\\.io\\'" . io-mode)
        '("\\.yml\\'" . yaml-mode)
        '("\\.yaml\\'" . yaml-mode)
        '("\\.lua\\'" . lua-mode))
        auto-mode-alist))

(setq fuel-listener-factor-binary "~/bin/factor")
(setq fuel-listener-factor-image "~/dev/misc/factor/factor.image")
(eval-after-load "comint"
  '(progn
     (define-key comint-mode-map (kbd "C-M-l")
       (fun-for-bind switch-to-buffer (other-buffer)))))

(setq w3m-use-cookies t)

(when nix
  (setq browse-url-browser-function 'browse-url-firefox
        browse-url-new-window-flag  t
        browse-url-firefox-new-window-is-tab t))

(setq ediff-window-setup-function 'ediff-setup-windows-plain)

;;;;;;;;;
;; Python
;;;;;;;;;

(eval-after-load "django-html-mode"
  '(progn
     (define-key django-html-mode-map "\C-c]" 'django-close-tag)))

(eval-after-load "python"
  '(progn
     (define-key python-mode-map (kbd "RET") 'newline-maybe-indent)

     (when (file-executable-p "/opt/local/bin/python")
       (setq python-python-command "/opt/local/bin/python")
       (setenv "PYMACS_PYTHON" "/opt/local/bin/python"))

     (when (require 'pymacs nil t)
       (pymacs-load "ropemacs" "rope-")
       (define-key ropemacs-local-keymap (kbd "M-/") 'dabbrev-expand)
       (defun rope-reload ()
         (interactive)
         (pymacs-terminate-services)
         (pymacs-load "ropemacs" "rope-")))))

;;;;;;;;;;
;; Flymake
;;;;;;;;;;

(defun find-executable (path fallback)
  (if (file-executable-p path)
      path
    fallback))

(when (load "flymake" t)
  (setq pyflakes-exe (find-executable "/opt/local/bin/pyflakes" "pyflakes"))
  (setq luac-exe (find-executable "/opt/local/bin/luac" "luac"))

  (defun flymake-pyflakes-init ()
    (let* ((temp-file (flymake-init-create-temp-buffer-copy
                       'flymake-create-temp-inplace))
           (local-file (file-relative-name
                        temp-file
                        (file-name-directory buffer-file-name))))
      (list pyflakes-exe (list local-file))))

  (defun flymake-lua-init ()
    "Invoke luac with '-p' to get syntax checking"
    (let* ((temp-file (flymake-init-create-temp-buffer-copy
                       'flymake-create-temp-inplace))
           (local-file (file-relative-name
                        temp-file
                        (file-name-directory buffer-file-name))))
      (list luac-exe (list "-p" local-file))))

  (add-to-list 'flymake-allowed-file-name-masks
               '("\\.py\\'" flymake-pyflakes-init))
  (add-to-list 'flymake-allowed-file-name-masks
               '("\\.lua\\'" flymake-lua-init))
  (push '("^.*luac[0-9.]*\\(.exe\\)?: *\\(.*\\):\\([0-9]+\\): \\(.*\\)$" 2 3 nil 4)
        flymake-err-line-patterns))

(add-hook 'python-mode-hook '(lambda () (flymake-mode 1)))
(add-hook 'lua-mode-hook '(lambda () (flymake-mode 1)))

(set-face-attribute 'flymake-errline nil
                    :background 'unspecified
                    :underline "orange")
(setq flymake-gui-warnings-enabled nil)

(require 'flymake-point nil t)

;; Lua

(defvaralias 'lua-indent-level 'tab-width)
(add-hook 'lua-mode-hook (lambda () (setq indent-tabs-mode t)))

;; Erlang

(when (file-directory-p "~/var/distel/elisp")
  (add-to-list 'load-path "~/var/distel/elisp"))
(autoload 'distel-setup "distel" nil t)

(defconst distel-shell-keys
  '(("\C-\M-i"   erl-complete)
    ("\M-?"      dabbrev-expand)
    ("\M-/"      dabbrev-expand)
    ("\M-."      erl-find-source-under-point)
    ("\M-,"      erl-find-source-unwind)
    ("\M-*"      erl-find-source-unwind)
    )
  "Additional keys to bind when in Erlang shell.")

(eval-after-load "erlang"
  '(progn
     (distel-setup)
     (define-key erlang-extended-mode-map (kbd "RET") 'newline-maybe-indent)
     (define-key erlang-extended-mode-map (kbd "M-/") 'dabbrev-expand)
     (add-hook 'erlang-shell-mode-hook
               (lambda ()
                 ;; add some Distel bindings to the Erlang shell
                 (dolist (spec distel-shell-keys)
                   (define-key erlang-shell-mode-map (car spec) (cadr spec)))))
     (add-hook 'erlang-mode-hook
               (lambda ()
                 ;; when starting an Erlang shell in Emacs, default in the node name
                 (setq inferior-erlang-machine-options '("-sname" "emacs"))))))

;; Snippets

(require 'yasnippet nil t)
(eval-after-load "yasnippet"
'(progn
   (global-unset-key (kbd "C-/"))
   (setq
    yas/trigger-key (kbd "C-/")
    yas/next-field-key (kbd "C-/"))
   (yas/initialize)
   (yas/load-directory "~/.emacs.d/snippets/")))


;; stardict
(autoload 'sdcv-search "sdcv-mode" nil t)
(setq sdcv-dictionary-list
      '("Universal (Ru-En)" "LingvoUniversal (En-Ru)" "Computers (En-Ru)"
        "Universal (Ru-En)" "LingvoUniversal (Ru-En)" "Computers (Ru-En)"))
(global-set-key (kbd "C-c d") 'sdcv-search)


;; highlight parentheses
(autoload 'highlight-parentheses-mode "highlight-parentheses" nil t)
(dolist (hook '(python-mode-hook
                emacs-lisp-mode-hook))
  (add-hook hook 'highlight-parentheses-mode))



;; smex

(require 'smex nil t)

(if (fboundp 'smex)
    (progn
      (smex-initialize)
      (smex-auto-update)
      (global-set-key (kbd "M-x") 'smex)
      (global-set-key (kbd "M-X") 'smex-major-mode-commands)
      (global-set-key (kbd "C-c M-x") 'smex-update-and-run)
      (global-set-key (kbd "C-c C-c M-x") 'execute-extended-command)))


;; sudo
(autoload 'sudo-unset-ro-or-save "sudo" "" t)
(autoload 'sudo-find-file "sudo" "" t)
(global-set-key (kbd "C-x M-s") 'sudo-unset-ro-or-save)
(global-set-key (kbd "C-x M-f") 'sudo-find-file)
