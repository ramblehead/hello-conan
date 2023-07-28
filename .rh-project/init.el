;; -*- coding: utf-8 -*-

(require 'cl)
(require 'hydra)
(require 'vterm)
(require 'flycheck)
(require 'lsp-mode)
(require 'lsp-javascript)
(require 'clang-format)

;;; hello-conan common command
;;; /b/{

(defvar hello-conan/build-buffer-name
  "*hello-conan-build*")

;; (defun hello-conan/lint ()
;;   (interactive)
;;   (rh-project-compile
;;    "yarn-run app:lint"
;;    hello-conan/build-buffer-name))

(defun hello-conan/build ()
  (interactive)
  (rh-project-compile
   "build.sh"
   hello-conan/build-buffer-name))

(defun hello-conan/clean ()
  (interactive)
  (rh-project-compile
   "clean-conan.sh"
   hello-conan/build-buffer-name))

;;; /b/}

;;; hello-conan
;;; /b/{

(defun hello-conan/hydra-define ()
  (defhydra hello-conan-hydra (:color blue :columns 5)
    "@hello-conan workspace commands"
    ;; ("l" hello-conan/lint "lint")
    ("b" hello-conan/build "build")
    ("c" hello-conan/clean "clean")))

(hello-conan/hydra-define)

(define-minor-mode hello-conan-mode
  "hello-conan project-specific minor mode."
  :lighter " hello-conan"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "<f9>") #'hello-conan-hydra/body)
            map))

(add-to-list 'rm-blacklist " hello-conan")

(defun hello-conan/lsp-deps-providers-path (path)
  (concat (expand-file-name (rh-project-get-root))
          "node_modules/.bin/"
          path))

(defvar hello-conan/lsp-clients-clangd-args '())

;; (setq lsp-clients-clangd-library-directories '("~/.platformio"))

(defun hello-conan/lsp-clangd-init ()
  (setq hello-conan/lsp-clients-clangd-args
        (copy-sequence lsp-clients-clangd-args))
  (add-to-list
   'hello-conan/lsp-clients-clangd-args
   "--query-driver=/usr/bin/g*-11,/usr/bin/clang*-16"
   t)

  ;; (add-hook
  ;;  'lsp-after-open-hook
  ;;  #'hello-conan/company-capf-c++-local-disable)

  ;; (add-hook
  ;;  'lsp-after-initialize-hook
  ;;  #'hello-conan/company-capf-c++-local-disable)
  )

;; (defun hello-conan/company-capf-c++-local-disable ()
;;   (when (eq major-mode 'c++-mode)
;;     (setq-local company-backends
;;                 (remq 'company-capf company-backends))))

(defun hello-conan/lsp-javascript-init ()
  (plist-put
   lsp-deps-providers
   :local (list :path #'hello-conan/lsp-deps-providers-path))

  (lsp-dependency 'typescript-language-server
                  '(:local "typescript-language-server"))

  (lsp--require-packages)

  (lsp-dependency 'typescript '(:local "tsserver"))

  (add-hook
   'lsp-after-initialize-hook
   #'hello-conan/flycheck-add-eslint-next-to-lsp))

(defun hello-conan/flycheck-add-eslint-next-to-lsp ()
  (when (seq-contains-p '(js2-mode typescript-mode web-mode) major-mode)
    (flycheck-add-next-checker 'lsp 'javascript-eslint)))

(defun hello-conan/flycheck-after-syntax-check-hook-once ()
  (remove-hook
   'flycheck-after-syntax-check-hook
   #'hello-conan/flycheck-after-syntax-check-hook-once
   t)
  (flycheck-buffer))

;; (eval-after-load 'lsp-javascript #'hello-conan/lsp-javascript-init)
(eval-after-load 'lsp-mode #'hello-conan/lsp-javascript-init)
(eval-after-load 'lsp-mode #'hello-conan/lsp-clangd-init)

(defun hello-conan-setup ()
  (when buffer-file-name
    (let ((project-root (rh-project-get-root))
          file-rpath ext-js)
      (when project-root
        (setq file-rpath (expand-file-name buffer-file-name project-root))
        (cond
         ;; This is required as tsserver does not work with files in archives
         ((bound-and-true-p archive-subfile-mode)
          (company-mode 1))

         ;; C/C++
         ((seq-contains '(c++-mode c-mode) major-mode)
          (when (rh-clangd-executable-find)
            (when (featurep 'lsp-mode)
              (setq-local
               lsp-clients-clangd-args
               (copy-sequence hello-conan/lsp-clients-clangd-args))

              (add-to-list
               'lsp-clients-clangd-args
               (concat "--compile-commands-dir="
                       (expand-file-name (rh-project-get-root)))
               t)

              (setq-local lsp-modeline-diagnostics-enable nil)
              ;; (lsp-headerline-breadcrumb-mode 1)

              (setq-local flycheck-checker-error-threshold 2000)

              (setq-local flycheck-idle-change-delay 3)
              (setq-local flycheck-check-syntax-automatically
                          ;; '(save mode-enabled)
                          '(idle-change save mode-enabled))))

          ;; (add-hook 'before-save-hook #'clang-format-buffer nil t)
          ;; (clang-format-mode 1)
          (company-mode 1)
          (lsp-deferred))

         ;; JavaScript/TypeScript
         ((or (setq
               ext-js
               (string-match-p
                (concat "\\.ts\\'\\|\\.tsx\\'\\|\\.js\\'\\|\\.jsx\\'"
                        "\\|\\.cjs\\'\\|\\.mjs\\'")
                file-rpath))
              (string-match-p "^#!.*node"
                              (or (save-excursion
                                    (goto-char (point-min))
                                    (thing-at-point 'line t))
                                  "")))

          (when (boundp 'rh-js2-additional-externs)
            (setq-local rh-js2-additional-externs
                        (append rh-js2-additional-externs
                                '("require" "exports" "module" "process"
                                  "__dirname"))))

          (setq-local flycheck-idle-change-delay 3)
          (setq-local flycheck-check-syntax-automatically
                      ;; '(save mode-enabled)
                      '(save idle-change mode-enabled))
          (setq-local flycheck-javascript-eslint-executable
                      (concat (expand-file-name project-root)
                              "node_modules/.bin/eslint"))

          (setq-local lsp-enabled-clients '(ts-ls))
          ;; (setq-local lsp-headerline-breadcrumb-enable nil)
          (setq-local lsp-before-save-edits nil)
          (setq-local lsp-modeline-diagnostics-enable nil)
          (add-hook
           'flycheck-after-syntax-check-hook
           #'hello-conan/flycheck-after-syntax-check-hook-once
           nil t)
          (lsp 1)
          ;; (lsp-headerline-breadcrumb-mode -1)
          (prettier-mode 1))

         ;; Python
         ((or (setq ext-js (string-match-p
                            (concat "\\.py\\'\\|\\.pyi\\'") file-rpath))
              (string-match-p "^#!.*python"
                              (or (save-excursion
                                    (goto-char (point-min))
                                    (thing-at-point 'line t))
                                  "")))

          ;;; /b/; pyright-lsp config
          ;;; /b/{

          (setq-local lsp-pyright-prefer-remote-env nil)
          (setq-local lsp-pyright-python-executable-cmd
                      (file-name-concat project-root ".venv/bin/python"))
          (setq-local lsp-pyright-venv-path
                      (file-name-concat project-root ".venv"))
          ;; (setq-local lsp-pyright-python-executable-cmd "poetry run python")
          ;; (setq-local lsp-pyright-langserver-command-args
          ;;             `(,(file-name-concat project-root ".venv/bin/pyright")
          ;;               "--stdio"))

          ;;; /b/}

          ;;; /b/; ruff-lsp config
          ;;; /b/{

          (setq-local lsp-ruff-lsp-server-command
                      `(,(file-name-concat project-root ".venv/bin/ruff-lsp")))
          (setq-local lsp-ruff-lsp-python-path
                      (file-name-concat project-root ".venv/bin/python"))
          (setq-local lsp-ruff-lsp-ruff-path
                      `[,(file-name-concat project-root ".venv/bin/ruff")])

          ;;; /b/}

          ;;; /b/; Python black
          ;;; /b/{

          (setq-local blacken-executable
                      (file-name-concat project-root ".venv/bin/black"))

          ;;; /b/}

          (setq-local lsp-enabled-clients '(pyright ruff-lsp))
          (setq-local lsp-before-save-edits nil)
          (setq-local lsp-modeline-diagnostics-enable nil)

          (blacken-mode 1)
          (run-with-idle-timer 0 nil #'lsp)))))))

;;; /b/}
