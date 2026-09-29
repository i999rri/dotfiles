;;; i999rri-urusi.el --- urusi-emacs の画面の組み立て -*- lexical-binding: t; -*-

;;; Commentary:

;; urusi-emacs (WinUI 3 の窓の中で Emacs を動かすもの) の中で動いている
;; ときの画面を決める。
;;
;; urusi-emacs に同梱されているのは、Emacs の画面をそのまま映す仕組みと、
;; タイトルバーなどを作るための部品だけ。何を作ってどう並べるかはこちらで
;; 決める。並べる部品は上から順に `urusi-screen-components' に書き、
;; `urusi-screen-windows' (Emacs の本体) が残りの高さを全部使う。
;; 何も書かなければ Windows 標準のタイトルバーの下に Emacs の画面がある
;; だけになる。
;;
;; urusi-emacs の外 (普通の Emacs) では読まない。init.el 側で
;; (featurep 'urusi) を見てから require する。

;;; Code:

(require 'urusi-screen)
(require 'i999rri-titlebar)
(require 'i999rri-child-frame)
(require 'i999rri-layout)
(require 'i999rri-tabs)
(require 'i999rri-statusbar)

(setq urusi-screen-components
      '(i999rri-titlebar
        urusi-layout-component
        i999rri-statusbar))

;; フレームの中身を Emacs 自身が描いた絵にする。Emacs はフォントファイルを自分で
;; 読んで字形をラスタライズするので、文字を組むときと描くときの寸法が同じに
;; なる。元に戻すなら urusi-screen-windows を指す。
(setq urusi-screen-frame-function #'urusi-screen-emacs)

;; 子フレーム (浮かぶ入力欄、補完のポップアップ) に影と角丸を付ける。
(setq urusi-screen-child-frame-function #'i999rri-child-frame)

;; 各窓の上の段のファイルのタブを、文字ではなくネイティブのタブで描く。
;; Emacs は段の場所を空けるだけにして、文字のタブは描かせない。描かせると
;; ネイティブのタブの下に隠れたまま、変わるたびに送られることになる。
(setq urusi-screen-tab-line-function #'i999rri-tab-line)
(setq host-draw-tab-lines nil)

(provide 'i999rri-urusi)
;;; i999rri-urusi.el ends here
