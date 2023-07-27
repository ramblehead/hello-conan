;; -*- coding: utf-8 -*-

(require 'cl)
(require 'hydra)
(require 'vterm)
(require 'flycheck)
(require 'lsp-mode)
(require 'lsp-javascript)
(require 'clang-format)

;;; mobility-separator-embedded common command
;;; /b/{

(defvar mobility-separator-embedded/build-buffer-name
  "*mobility-separator-embedded-build*")

(defun mobility-separator-embedded/lint ()
  (interactive)
  (rh-project-compile
   "yarn-run app:lint"
   mobility-separator-embedded/build-buffer-name))

(defun mobility-separator-embedded/build ()
  (interactive)
  (rh-project-compile
   "yarn-run app:build"
   mobility-separator-embedded/build-buffer-name))

(defun mobility-separator-embedded/clean ()
  (interactive)
  (rh-project-compile
   "yarn-run app:clean"
   mobility-separator-embedded/build-buffer-name))

;;; /b/}

;;; mobility-separator-embedded
;;; /b/{

(defun mobility-separator-embedded/hydra-define ()
  (defhydra mobility-separator-embedded-hydra (:color blue :columns 5)
    "@mobility-separator-embedded workspace commands"
    ("l" mobility-separator-embedded/lint "lint")
    ("b" mobility-separator-embedded/build "build")
    ("c" mobility-separator-embedded/clean "clean")))

(mobility-separator-embedded/hydra-define)

(define-minor-mode mobility-separator-embedded-mode
  "mobility-separator-embedded project-specific minor mode."
  :lighter " mobility-separator-embedded"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "<f9>") #'mobility-separator-embedded-hydra/body)
            map))

(add-to-list 'rm-blacklist " mobility-separator-embedded")

(defun mobility-separator-embedded/lsp-deps-providers-path (path)
  (concat (expand-file-name (rh-project-get-root))
          "node_modules/.bin/"
          path))

(defvar mobility-separator-embedded/lsp-clients-clangd-args '())

(setq lsp-clients-clangd-library-directories '("~/.platformio"))

(defun mobility-separator-embedded/config-lsp-clangd ()
  ;; (setq
  ;;  lsp-clients-clangd-executable
  ;;  "/home/rh/.vscode/extensions/ms-vscode.cpptools-1.16.3-linux-x64/LLVM/bin")
  (setq mobility-separator-embedded/lsp-clients-clangd-args
        (copy-sequence lsp-clients-clangd-args))
  (add-to-list
   'mobility-separator-embedded/lsp-clients-clangd-args
   ;; "--query-driver=/usr/bin/g*-11,/usr/bin/clang*-14"
   "--query-driver=/home/rh/.platformio/packages/toolchain-gccarmnoneeabi/bin/arm-none-eabi-g*"
   t)

  ;; (add-hook
  ;;  'lsp-after-open-hook
  ;;  #'mobility-separator-embedded/company-capf-c++-local-disable)

  ;; (add-hook
  ;;  'lsp-after-initialize-hook
  ;;  #'mobility-separator-embedded/company-capf-c++-local-disable)
  )

;; (defun mobility-separator-embedded/company-capf-c++-local-disable ()
;;   (when (eq major-mode 'c++-mode)
;;     (setq-local company-backends
;;                 (remq 'company-capf company-backends))))

(defun mobility-separator-embedded/config-lsp-javascript ()
  (plist-put
   lsp-deps-providers
   :local (list :path #'mobility-separator-embedded/lsp-deps-providers-path))

  (lsp-dependency 'typescript-language-server
                  '(:local "typescript-language-server"))

  (lsp--require-packages)

  (lsp-dependency 'typescript '(:local "tsserver"))

  (add-hook
   'lsp-after-initialize-hook
   #'mobility-separator-embedded/flycheck-add-eslint-next-to-lsp))

(defun mobility-separator-embedded/flycheck-add-eslint-next-to-lsp ()
  (when (seq-contains-p '(js2-mode typescript-mode web-mode) major-mode)
    (flycheck-add-next-checker 'lsp 'javascript-eslint)))

(defun mobility-separator-embedded/flycheck-after-syntax-check-hook-once ()
  (remove-hook
   'flycheck-after-syntax-check-hook
   #'mobility-separator-embedded/flycheck-after-syntax-check-hook-once
   t)
  (flycheck-buffer))

;; (eval-after-load 'lsp-javascript #'mobility-separator-embedded/config-lsp-javascript)
(eval-after-load 'lsp-mode #'mobility-separator-embedded/config-lsp-javascript)
(eval-after-load 'lsp-mode #'mobility-separator-embedded/config-lsp-clangd)

(defun mobility-separator-embedded-setup ()
  (when buffer-file-name
    (let ((project-root (rh-project-get-root))
          file-rpath ext-js)
      (when project-root
        (setq file-rpath (expand-file-name buffer-file-name project-root))
        (cond
         ;; This is required as tsserver does not work with files in archives
         ((bound-and-true-p archive-subfile-mode)
          (company-mode 1))

         ((seq-contains '(c++-mode c-mode) major-mode)
          (when (rh-clangd-executable-find)
            (when (featurep 'lsp-mode)
              (setq-local
               lsp-clients-clangd-args
               (copy-sequence mobility-separator-embedded/lsp-clients-clangd-args))

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
           #'mobility-separator-embedded/flycheck-after-syntax-check-hook-once
           nil t)
          (lsp 1)
          ;; (lsp-headerline-breadcrumb-mode -1)
          (prettier-mode 1)))))))

;;; /b/}
