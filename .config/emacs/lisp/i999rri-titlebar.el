;;; i999rri-titlebar.el --- urusi-emacs のタイトルバー -*- lexical-binding: t; -*-

;;; Commentary:

;; urusi-emacs の窓のタイトルバー。urusi-titlebar が用意している部品
;; (タイトルと、最小化・最大化・閉じるのボタン) を並べて作る。
;;
;; urusi-titlebar という名前の要素が、ドラッグで窓を動かせる領域になる。
;; 上に置いたボタンなどはそのまま押せるので、ここに何を足してもいい。

;;; Code:

(require 'urusi-screen)
(require 'urusi-titlebar)

(defface i999rri-titlebar
  '((t :inherit default))
  "タイトルバーの face。背景がバーの色、前景が文字とボタンの記号の色。"
  :group 'urusi)

(defvar i999rri-titlebar-height 32
  "タイトルバーの高さ (XAML の単位)。Windows 標準と同じ。")

(defun i999rri-titlebar--color (attribute frame)
  "FRAME での `i999rri-titlebar' の ATTRIBUTE の色を XAML の形で返す。"
  (urusi-screen-color (face-attribute 'i999rri-titlebar attribute frame t)))

(defun i999rri-titlebar (frame)
  "FRAME のタイトルバーを返す。`urusi-screen-components' に並べて使う。
色は FRAME (窓に映っているフレーム) のものを使う。子フレーム (mini-frame
など) は独自の色を持つことがあり、選択中のフレームの色を読むと、それが
開いている間だけバーの色が変わってしまう。"
  (let ((background (i999rri-titlebar--color :background frame))
        (foreground (i999rri-titlebar--color :foreground frame)))
    `(Grid :Name "urusi-titlebar"
           :Height ,i999rri-titlebar-height
           ,@(when background `(:Background ,background))
           (Grid.ColumnDefinitions
            (ColumnDefinition :Width "*")
            (ColumnDefinition :Width "Auto"))
           ,(apply #'urusi-titlebar-title
                   :Margin "12,0,0,0"
                   (when foreground `(:Foreground ,foreground)))
           ,(urusi-titlebar-buttons :Grid.Column 1
                                    :height i999rri-titlebar-height
                                    :foreground foreground))))

(provide 'i999rri-titlebar)
;;; i999rri-titlebar.el ends here
