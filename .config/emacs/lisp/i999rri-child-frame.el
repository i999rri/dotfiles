;;; i999rri-child-frame.el --- urusi-emacs の子フレームの見た目 -*- lexical-binding: t; -*-

;;; Commentary:

;; urusi-emacs が描く子フレーム (浮かぶ入力欄、補完のポップアップなど) に
;; 影と角丸を付ける。置く位置と大きさは Emacs が決め、ここでは中身を包む
;; だけ。中身は urusi-emacs の `urusi-screen-child-frame-body' が描く。
;;
;; 影は Windows のメニューなどと同じ `ThemeShadow'。`Translation' の 3 つ目
;; の数字が浮かせる高さで、大きいほど影が広く柔らかくなる。暗い背景では
;; 薄くしか見えないが、Windows 自身の影も同じ。
;;
;; 影で周りから浮いて見えるので、影を付けるフレームには Emacs の枠
;; (`child-frame-border') を描かない。

;;; Code:

(require 'urusi-screen)

(defun i999rri-child-frame--minibuffer-p (frame)
  "FRAME が mini-frame の浮かぶ入力欄なら non-nil を返す。"
  (eq (frame-parameter frame 'minibuffer) 'only))

(defun i999rri-child-frame--corfu-p (frame)
  "FRAME が corfu の補完のポップアップなら non-nil を返す。"
  (equal (buffer-name (window-buffer (frame-root-window frame))) " *corfu*"))

(defun i999rri-child-frame (frame)
  "子フレーム FRAME を描く。`urusi-screen-child-frame-function' に使う。
入力欄は大きく浮かせて角を丸め、補完は小さな影だけにする。どちらも枠は
描かない。ほかの子フレームは Emacs が描くままにする。"
  (cond
   ((i999rri-child-frame--minibuffer-p frame)
    `(Border :CornerRadius 8
             :Translation "0,0,32"
             (Border.Shadow (ThemeShadow))
             ,(urusi-screen-child-frame-body frame :border nil :corner-radius 8)))
   ((i999rri-child-frame--corfu-p frame)
    `(Border :Translation "0,0,16"
             (Border.Shadow (ThemeShadow))
             ,(urusi-screen-child-frame-body frame :border nil)))
   (t (urusi-screen-child-frame-body frame))))

(provide 'i999rri-child-frame)
;;; i999rri-child-frame.el ends here
