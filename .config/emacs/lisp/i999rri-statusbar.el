;;; i999rri-statusbar.el --- urusi-emacs のステータスバー -*- lexical-binding: t; -*-

;;; Commentary:

;; Visual Studio のように、窓の一番下に 1 本だけステータスバーを置く。いま作業
;; している窓について、ブランチ・バッファ・エラーの数・カーソルの位置・文字コード・
;; メジャーモードを出す。色はモードライン (テーマの `mode-line') から取る。
;;
;; 同じことを言うので、各窓のモードラインは出さない。窓どうしの境目は、モード
;; ラインの代わりに 1px の区切り線 (window-divider) で示す。

;;; Code:

(require 'urusi-screen)
(require 'urusi-statusbar)

(defvar i999rri-statusbar-height 24
  "ステータスバーの高さ (XAML の単位)。Visual Studio と同じくらい。")

(defun i999rri-statusbar--color (attribute frame)
  "FRAME での `mode-line' の ATTRIBUTE の色を XAML の形で返す。"
  (urusi-screen-color (face-attribute 'mode-line attribute frame t)))

(defun i999rri-statusbar (frame)
  "FRAME の一番下に置くステータスバー。"
  (urusi-statusbar frame
                   :left '(urusi-statusbar-vc
                           urusi-statusbar-buffer)
                   :right '(urusi-statusbar-diagnostics
                            urusi-statusbar-position
                            urusi-statusbar-encoding
                            urusi-statusbar-major-mode)
                   :Height i999rri-statusbar-height
                   :Background (or (i999rri-statusbar--color :background frame)
                                   "Transparent")
                   :Foreground (or (i999rri-statusbar--color :foreground frame)
                                   "White")))

(defun i999rri-statusbar-hide-mode-lines ()
  "各窓のモードラインを消し、窓の境目を区切り線で示す。"
  ;; doom-modeline はモードを有効にするたびに既定の mode-line-format を
  ;; 書き換えるため、先に止める
  (when (bound-and-true-p doom-modeline-mode)
    (doom-modeline-mode -1))
  (setq-default mode-line-format nil)
  (setq window-divider-default-places t
        window-divider-default-bottom-width 1
        window-divider-default-right-width 1)
  (window-divider-mode 1))

;; doom-modeline は elpaca が init の後で読むため、それが済んでから消す。
(add-hook (if (boundp 'elpaca-after-init-hook) 'elpaca-after-init-hook 'after-init-hook)
          #'i999rri-statusbar-hide-mode-lines 90)

(provide 'i999rri-statusbar)
;;; i999rri-statusbar.el ends here
