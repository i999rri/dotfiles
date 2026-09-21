;;; i999rri-layout.el --- urusi-emacs の画面の分け方 -*- lexical-binding: t; -*-

;;; Commentary:

;; urusi-emacs の窓を、上の Emacs 本体と下の出力パネルに分ける。
;;
;; 出力パネルはふだん隠しておき、M-x compile の出力 (*compilation*) を
;; 出すときに開く。C-c o で開け閉めできる。パネルの中の q (quit-window) で
;; 閉じるのは urusi-emacs 側の動き。
;; パネルの中身は Emacs のフレームなので、出力はふつうのバッファとして
;; 読める (エラーの行から飛ぶなど)。

;;; Code:

(require 'urusi-layout)

(setq urusi-layout
      '(column
        (panel :id editor :content emacs)
        (panel :id output :size 220 :hidden t
               :content frame :buffer "*compilation*")))

;; ビルドの出力は出力パネルへ。隠れていれば開く
(add-to-list 'display-buffer-alist
             '("\\*compilation\\*"
               (urusi-layout-display-in-panel)
               (panel . output)))

;; 出力パネルの上にはタブの行を出さない。並ぶのは出力と関係ないバッファなので
(defun i999rri-layout--plain-output (frame id)
  "出力パネルのフレーム FRAME からタブの行を外す。ID はパネルの :id。"
  (when (eq id 'output)
    (let ((window (frame-root-window frame)))
      (set-window-parameter window 'tab-line-format 'none)
      (set-window-parameter window 'header-line-format 'none))))

(add-hook 'urusi-layout-make-frame-functions #'i999rri-layout--plain-output)

(defun i999rri-layout-toggle-output ()
  "出力パネルを開け閉めする。"
  (interactive)
  (urusi-layout-toggle 'output))

(keymap-global-set "C-c o" #'i999rri-layout-toggle-output)

(provide 'i999rri-layout)
;;; i999rri-layout.el ends here
