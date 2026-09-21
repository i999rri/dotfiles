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
;;
;; 入力中の which-key の一覧は、init.el が入力欄のすぐ下に子フレームとして
;; 並べる。一覧が出ている間は、入力欄と一覧を 1 枚の板に見せるため、入力欄は
;; 上の角だけ、一覧は下の角だけを丸める。

;;; Code:

(require 'urusi-screen)

(defun i999rri-child-frame--minibuffer-p (frame)
  "FRAME が mini-frame の浮かぶ入力欄なら non-nil を返す。"
  (eq (frame-parameter frame 'minibuffer) 'only))

(defun i999rri-child-frame--which-key-p (frame)
  "FRAME が入力欄の下に並べた which-key の一覧なら non-nil を返す。"
  (equal (frame-parameter frame 'name) "which-key"))

(defun i999rri-child-frame--which-key-shown-p ()
  "入力欄の下に which-key の一覧が出ていれば non-nil を返す。"
  (and (boundp 'which-key--frame)
       (frame-live-p which-key--frame)
       (eq (frame-visible-p which-key--frame) t)
       (i999rri-child-frame--which-key-p which-key--frame)))

(defun i999rri-child-frame--floating (frame radius depth)
  "FRAME を枠なし・角丸 RADIUS で、高さ DEPTH だけ浮かせて描く。"
  `(Border :CornerRadius ,radius
           :Translation ,(format "0,0,%d" depth)
           (Border.Shadow (ThemeShadow))
           ,(urusi-screen-child-frame-body frame :border nil :corner-radius radius)))

(defun i999rri-child-frame--corfu-p (frame)
  "FRAME が corfu の補完のポップアップなら non-nil を返す。"
  (equal (buffer-name (window-buffer (frame-root-window frame))) " *corfu*"))

(defun i999rri-child-frame (frame)
  "子フレーム FRAME を描く。`urusi-screen-child-frame-function' に使う。
入力欄 (と、その下の which-key の一覧) は大きく浮かせて角を丸め、補完は
小さな影だけにする。どれも枠は描かない。ほかの子フレームは Emacs が
描くままにする。"
  (cond
   ((i999rri-child-frame--minibuffer-p frame)
    (i999rri-child-frame--floating
     frame (if (i999rri-child-frame--which-key-shown-p) "8,8,0,0" 8) 32))
   ((i999rri-child-frame--which-key-p frame)
    (i999rri-child-frame--floating frame "0,0,8,8" 32))
   ((i999rri-child-frame--corfu-p frame)
    `(Border :Translation "0,0,16"
             (Border.Shadow (ThemeShadow))
             ,(urusi-screen-child-frame-body frame :border nil)))
   (t (urusi-screen-child-frame-body frame))))

(provide 'i999rri-child-frame)
;;; i999rri-child-frame.el ends here
