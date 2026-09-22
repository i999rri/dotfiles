;;; i999rri-layout.el --- urusi-emacs の画面の分け方 -*- lexical-binding: t; -*-

;;; Commentary:

;; urusi-emacs の窓の下のほうに、出力パネルを Emacs 本体に重ねて浮かべる。
;; 重ねるので、開いても本体の大きさは変わらない。上端にはタブと同じ
;; オレンジの線を引く。
;;
;; 出力パネルはふだん隠しておき、M-x compile の出力 (*compilation*) を
;; 出すときに開く。C-c o で開け閉めできる。パネルの中の q (quit-window) で
;; 閉じるのは urusi-emacs 側の動き。
;; パネルの中身は Emacs のフレームなので、出力はふつうのバッファとして
;; 読める (エラーの行から飛ぶなど)。

;;; Code:

(require 'urusi-layout)

(defun i999rri-layout-accent (_frame)
  "出力パネルの上端の線の色。選択中のタブの色に合わせる。"
  (urusi-screen-color (face-attribute 'tab-line-tab-current :background nil t)))

;; 出力パネルの上の空き (:content nil) は何も描かないので、下の本体が見えて
;; クリックも本体に届く
(setq urusi-layout
      '(layer
        (panel :id editor :content emacs)
        (column
         (panel :content nil)
         (panel :id output :size 220 :hidden t
                :content frame :buffer "*compilation*"
                :border-brush i999rri-layout-accent
                :border-thickness "0,1,0,0"))))

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

;; ビルドの出力には行番号を出さない。行番号は global-display-line-numbers-mode で
;; 全部のバッファに付けているので、付ける関数のほうで飛ばす。例外の一覧
;; (display-line-numbers-exempt-modes) は urusi-emacs の Emacs にはまだない
(defun i999rri-layout--skip-line-numbers (&rest _)
  "ビルドの出力のバッファなら non-nil を返し、行番号を付けさせない。"
  (derived-mode-p 'compilation-mode))

(advice-add 'display-line-numbers--turn-on :before-until
            #'i999rri-layout--skip-line-numbers)

;; ビルドの出力は本体より 1 段小さい文字で出す。フレームの default を変えると
;; テーマを切り替えたときに戻るので、バッファの文字の倍率で小さくする
(defun i999rri-layout--small-output ()
  "今のバッファの文字を 1 段小さくする。"
  (text-scale-set -1))

(add-hook 'compilation-mode-hook #'i999rri-layout--small-output)

(defun i999rri-layout-toggle-output ()
  "出力パネルを開け閉めする。"
  (interactive)
  (urusi-layout-toggle 'output))

(keymap-global-set "C-c o" #'i999rri-layout-toggle-output)

(provide 'i999rri-layout)
;;; i999rri-layout.el ends here
