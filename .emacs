(require 'package)
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/"))
(package-initialize)
(elpy-enable)

(require 'use-package)
;; Uncomment this next line if you want line numbers on the left side
(global-linum-mode 1)
(global-set-key "\C-c\C-v" 'compile)
(setq line-number-mode t)
(setq column-number-mode t)
(display-time)
(global-font-lock-mode t)
(setq font-lock-maximum-decoration t)

;;This makes rainbow delimiters mode the default.
;;comment out to turn it off.
(add-hook 'find-file-hook 'rainbow-delimiters-mode-enable)

;;Want electric pair mode? Uncomment the next line
;(electric-pair-mode)

;;Want to turn off show paren mode? Comment out the below line.
(show-paren-mode)

;;; yasnippet
;;; should be loaded before auto complete so that they can work together
(require 'yasnippet)
(yas-global-mode 1)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(column-number-mode t)
 '(compilation-auto-jump-to-first-error nil)
 '(dap-auto-show-output nil)
 '(dap-java-test-additional-args '("--include-classname" ".+"))
 '(dcoverage-moderate-covered-report-color "dark orange")
 '(dcoverage-package-name-elide "edu.duke.ece651.")
 '(dcoverage-pooly-covered-report-color "red")
 '(dcoverage-well-covered-report-color "green")
 '(display-time-mode t)
 '(elpy-django-always-prompt t)
 '(elpy-get-info-from-shell t)
 '(inhibit-startup-screen t)
 '(lsp-java-format-on-type-enabled nil)
 '(package-selected-packages
   '(php-mode web-mode lsp-treemacs company-jedi jedi blacken python-django pyenv-mode elpy rainbow-mode rainbow-delimiters flycheck company yasnippet-snippets xref-js2 js2-refactor js2-mode lsp-ivy use-package helm-lsp dracula-theme posframe lsp-ui lsp-mode groovy-mode forge magit memoize lsp-javacomp lsp-java jtags javadoc-lookup java-imports gradle-mode flycheck-popup-tip flycheck-gradle company-rtags company-c-headers clang-format))
 '(python-shell-completion-native-disabled-interpreters '("pypy" "ipython" "python3"))
 '(python-shell-interpreter "python3")
 '(safe-local-variable-values '((TeX-master . t)))
 '(show-paren-mode t))



(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:family "Ubuntu Mono" :foundry "DAMA" :slant normal :weight normal :height 120 :width normal))))
 '(lsp-ui-peek-line-number ((t (:foreground "deep sky blue"))))
 '(lsp-ui-peek-selection ((t (:background "blue" :foreground "white smoke"))))
 '(lsp-ui-sideline-code-action ((t (:background "black" :foreground "lawn green")))))


(global-set-key "\C-x\C-g" 'goto-line)

;; For auto-complete
(use-package company)
(global-company-mode)
(require 'company)
(require 'company-rtags)
(add-hook 'after-init-hook 'global-company-mode)
(global-company-mode)

(defun my/python-mode-hook ()
  (add-to-list 'company-backends 'company-jedi))
(add-hook 'python-mode-hook 'my/python-mode-hook)

;; Enable Flycheck
(when (load "flycheck" t t)
  (setq elpy-modules (delq 'elpy-module-flymake elpy-modules))
  (add-hook 'elpy-mode-hook 'flycheck-mode))
;; auto format code on save for python
(add-hook 'elpy-mode-hook (lambda ()
                            (add-hook 'before-save-hook
                                      'elpy-format-code nil t)))

;; django key setup


; Automatically set compilation mode to
; move to an error when you move the point over it
(add-hook 'compilation-mode-hook
(lambda () 
(progn
     (next-error-follow-minor-mode))))

;;Automatically go to the first error
;;This works great for C/C++---not so much for Java
;; (results in a lot of trying to find the file, since the full path
;; isn't usually in the error message)
;(setq compilation-auto-jump-to-first-error t)
(setq-default indent-tabs-mode nil)

(add-hook 'gud-mode-hook (lambda() (company-mode 0)))

(setq gdb-many-windows t
      gdb-use-separate-io-buffer t)
(advice-add 'gdb-setup-windows :after (lambda() (set-window-dedicated-p (selected-window) t)))

(defconst gud-windown-register 123456)

(defun gud-quit()
  (interactive)
  (gud-basic-call "quit"))

(add-hook 'gud-mode-hook
          (lambda()
            (gud-tooltip-mode)
            (window-configuration-to-register gud-windown-register)
            (local-set-key (kbd "C-q") 'gud-quit)))

(advice-add 'gud-sentinel :after
            (lambda (proc msg)
              (when (memq (process-status proc) '(signal exit))
                (jump-to-register gud-windown-register)
                (bury-buffer))))
            


(use-package gradle-mode)
(use-package lsp-mode
  :init
  (setq lsp-keymap-prefix "C-c l")
  :hook
  ((java-mode . lsp))
  :commands lsp
  )
(use-package lsp-ui :commands lsp-ui-mode)
(use-package helm-lsp :commands helm-lsp-workspace-symbol)
(use-package lsp-ivy :commands lsp-ivy-workspace-symbol)
(use-package lsp-treemacs :commands lsp-treemacs-errors-list)
(use-package dap-mode)
(use-package dap-java)
;(use-package lsp-java)


(defun find-path-component(path target)
  "Find TARGET in PATH, returning a list of all components found along the way. 
Returns t if TARGET not found."
  (cond ((equal path "") t)
        ((equal target (file-name-nondirectory path)) nil)
        ((equal path "/") t)
        (t (let ((tmp (find-path-component (directory-file-name (file-name-directory path)) target)))
             (if (equal tmp t)
                 t
               (cons (file-name-nondirectory path) tmp))))))

(defun java-smart-class-skel ()
  "Generate a Java class skeleton based on the current path."
  (interactive)

  (let* ((bname (buffer-file-name))
         (cname (file-name-base bname))
         (ctype (find-path-component bname "src"))
         (istest (if (listp ctype) (equal (car (reverse ctype)) "test") nil))
         (pkg (find-path-component bname "java")))
    (if (and (listp pkg)
             (> (length pkg) 1))
        (progn
          (insert "package ")
          (insert (mapconcat 'identity (reverse (cdr pkg)) "."))
          (insert ";\n\n")))
    (if istest
        (progn
          (insert "import static org.junit.jupiter.api.Assertions.*;\n\n")
          (insert "import org.junit.jupiter.api.Test;\n\n")))
    (insert "public class " cname " ")
    (insert "{\n")
    (if istest
          (insert "  @Test\n  public void test_() {\n\n  }\n"))
    (insert "\n")
    (insert "}\n")
    (if istest
        (progn
          (search-backward "public void test_()")
          (search-forward "()")
          (backward-char 2))
      
      (progn
        (goto-char (point-min))
        (search-forward (concat "public class " cname))))
    (if (buffer-file-name) (save-buffer))))
(use-package hydra)        



(use-package elquery)
(add-to-list 'load-path "~/.emacs.d/dcoverage/")
(use-package dcoverage)
(use-package yasnippet)
(yas-global-mode)
(defun build-and-run ()
  "Single key stroke for gradle to build and run the program."
  (interactive)
  (gradle-run "--info build run"))

(define-key gradle-mode-map (kbd "C-c C-r") 'build-and-run)

(add-to-list 'auto-mode-alist '("build.gradle" . groovy-mode))


(use-package magit
  :defer 2
  :config (global-set-key "\C-cg" 'magit-status))
(use-package forge
  :defer 5
  :config (add-to-list 'forge-alist '("gitlab.oit.duke.edu"  "gitlab.oit.duke.edu/api/v4" "gitlab.oit.duke.edu" forge-gitlab-repository)))

(add-hook 'dap-stopped-hook
          (lambda (arg)
            (call-interactively #'dap-hydra)))

(global-set-key "\C-c\C-h" 'hydra-pause-resume)

(add-hook 'dap-terminated-hook
           (lambda (arg)
             (hydra-disable)))




(defun gradle-clean-and-build ()
  "Run gradle clean build."
  (interactive)
  (gradle-run "clean classes testClasses"))

(defun ece651-debug-test-case()
  "Ensure that classes are up to date, copy to bin, and debug current test."
  (interactive)
  ;;we'll make sure everything is up to date
  (let* ((basedir (dcoverage-find-project-root))
         (testdir (f-join basedir "build" "classes" "java" "test"))
         (maindir (f-join basedir "build" "classes" "java" "main"))
         (cloverdir (f-join maindir "clover.instrumented"))
         (bindir (f-join basedir "bin"))
         (testdest (f-join bindir "test"))
         (maindest (f-join bindir "main")))
    ;;check that build made these before continuing
    (if (not (file-directory-p testdir))
        (error "Test directory %s does not exist (run gradle?)" testdir))
    (if (not (file-directory-p maindir))
        (error "Main directory %s does not exist (run gradle?)" maindir))
    (if (file-directory-p cloverdir)
        (error "It looks like your code is instrumented.  Run gradle-clean-and-build first!"))
    ;;copy build dirs to bin/
    (delete-directory testdest t)
    (delete-directory maindest t)
    (copy-directory testdir testdest t t nil)
    (copy-directory maindir maindest t t nil)
    ;;now we can run the debugger
    (message "Starting debugger... %s" (current-buffer))
    (dap-breakpoint-add)
    (save-window-excursion (call-interactively 'dap-java-debug-test-method))
    (message "Press C-c C-h to toggle debug hydra")
    (cons "debugger started" "debugging")))

    
;ctype should be '(classbuilder java main test)
(defun toggle-code-to-test-buffer()
  "Switch between code and test for a given class.   If the test code doesn't exist, init it."
  (interactive)
  (let* ((prjroot (dcoverage-find-project-root))
         (bname (buffer-file-name))
         (fext   (file-name-extension bname))
         (cname (file-name-base bname))
         (ctype (find-path-component bname "src"))
         (istest (if (listp ctype) (equal (car (reverse ctype)) "test") nil))
         (pkg (find-path-component bname "java")))
    (if (not (equal fext "java"))
        (error "%s is not a .java file" bname))
    (if (and istest (not (string-suffix-p "Test" cname)))
        (error "%s is in test directory but is not named (something)Test.java"))
    (let* ((newname (if istest
                         (substring cname 0 -4)  ;; test -> non test: remove Test from name
                       (concat cname "Test")))   ;; non test -> test add Test to name
           (testormain (if istest "main" "test"))  ;; swap test/main names
            ;;now we need prjroot/src/[test|main]/(all the stuff in cdr ctype)/newname.java
           (packagename (apply 'f-join (cdr (reverse (cdr ctype)))))
           (ign (message "(f-join %s %s %s %s)" prjroot "src" testormain packagename))
           (theotherdir (f-join prjroot "src" testormain packagename ))
           (ignored (make-directory theotherdir t))
           (theotherfile (f-join theotherdir (concat newname ".java")))
           (ignored (message "Switching to %s " theotherfile))
           (thebuffer (find-file theotherfile)))
      (if (= (buffer-size thebuffer) 0)
          (java-smart-class-skel)))))
            


(add-hook 'java-mode-hook
          (lambda()
            (flycheck-mode +1)
            (setq c-basic-offset 2)
            (gradle-mode)
            (dap-mode 1)
            (dap-ui-mode 1)
            (dap-tooltip-mode 1)
            (tooltip-mode 1)
            (if (not window-system)
                (setq dap-auto-configure-features (remove 'controls dap-auto-configure-features)))
            ;(dap-ui-controls-mode 1)
            ;(lsp)
            (local-set-key "\C-c\C-a" 'lsp-java-add-unimplemented-methods)
            (local-set-key "\C-c\C-i" 'lsp-java-organize-imports)
            (local-set-key "\C-c\C-o" 'lsp-java-generate-overrides)
            (local-set-key "\M-gg" 'lsp-java-generate-getters-and-setters)
            (local-set-key "\C-c\C-e" 'lsp-java-extract-method)
            (local-set-key "\C-ci" 'lsp-goto-implementation)
            (local-set-key "\C-ct" 'lsp-goto-type-definition)
            (local-set-key "\C-c\C-j" 'javadoc-lookup)
            (local-set-key "\C-c\C-v" 'gradle-execute)
            (local-set-key "\C-c\C-f" 'lsp-format-buffer)
            (local-set-key "\C-cr" 'lsp-rename)
            (local-set-key "\C-cd" 'lsp-ui-peek-find-definitions)
            (local-set-key "\C-cu" 'lsp-ui-peek-find-references)
            (local-set-key "\C-cx"  'gradle-clean-and-build)
            (local-set-key "\C-c\C-s" 'java-smart-class-skel)
            (local-set-key "\C-c\C-d" 'ece651-debug-test-case)
            (local-set-key "\C-xt" 'toggle-code-to-test-buffer)
            (setq tab-width 2)))
                 
(add-hook 'latex-mode-hook 'flyspell-mode)
(add-hook 'latex-mode-hook 'flyspell-buffer)

(load-theme 'dracula t)



;; for clang-formatting
(use-package clang-format)
(add-hook 'c-mode-hook
          (function (lambda ()
                    (add-hook 'write-contents-functions
                              (lambda() (progn (clang-format-buffer) nil))))))

(add-hook 'c++-mode-hook
          (function (lambda ()
                      (add-hook 'write-contents-functions
                                (lambda() (progn (clang-format-buffer) nil))))))

