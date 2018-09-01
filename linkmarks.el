;;; linkmarks.el --- Org-mode link based bookmarks -*- lexical-binding: t; -*-

;; Copyright (C) 2018 Dustin Lacewell

;; Author: Dustin Lacewell <dlacewell@gmail.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "24") (helm "0") (dash "0")
;; Keywords: bookmarks, org
;; URL: http://github.com/dustinlacewell/linkmarks

;;; Commentary:

;; This package lets you use org-mode links as bookmarks.

;;; Code:
(require 'seq)
(require 'helm)
(require 'dash)



;;;###autoload
(defgroup linkmarks nil
  "Configuration options for linkmarks."
  :group 'org)


(defcustom linkmarks-file (expand-file-name "~/org/bookmarks.org")
  "Define linkmarks file to store your bookmarks in."
  :group 'linkmarks
  :type 'string)



(defun linkmarks--setup ()
  (setq org-outline-path-complete-in-steps nil)
  (setq org-link-frame-setup '((elisp . find-file)
                               (vm . vm-visit-folder-other-frame)
                               (vm-imap . vm-visit-imap-folder-other-frame)
                               (gnus . org-gnus-no-new-news)
                               (file . find-file)
                               (wl . wl-other-frame)))
  (setq org-refile-use-outline-path t)
  (setq org-refile-targets `((,linkmarks-file :maxlevel . 99)))
  (setq org-confirm-elisp-link-function nil)
  (setq safe-local-variable-values '((org-confirm-elisp-link-function . nil))))

(defun linkmarks--in-file ()
  (linkmarks--setup)
  (with-temp-buffer
    (insert-file-contents linkmarks-file t)
    (org-mode)
    (goto-char (point-min))
    (outline-show-all)
    (cl-loop
     for target in (org-refile-get-targets)
     for element = (progn
                     (goto-char (nth 3 target))
                     (forward-line)
                     (org-element-context))
     for type = (car element)
     for props = (cadr element)
     for begin = (plist-get props :begin)
     for end = (plist-get props :end)
     for content = (buffer-substring begin end)
     if (equal 'link type)
     collect (list (car target) content))))

(defun linkmarks-select ()
  (interactive)
  (-let* ((targets (linkmarks--in-file))
          (choices (mapcar 'car targets))
          (choice (completing-read "Bookmark" choices))
          ((_ link) (-first (lambda (i) (equal (car i) choice)) targets)))
    (org-open-link-from-string link)))

(defun linkmarks-capture ()
  (interactive)
  (let ((org-capture-entry '("t" "Bookmark" entry (file "~/org/bookmarks.org")
                             "* %^{Title}\n[[%?]]\n  added: %U" '(:kill-buffer))))
    (linkmarks--setup)
    (org-capture)))



(provide 'linkmarks)

;;; linkmarks.el ends here
