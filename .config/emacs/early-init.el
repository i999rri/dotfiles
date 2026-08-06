;;; early-init.el --- init.el より前に読まれる設定 -*- lexical-binding: t; -*-

;;; Commentary:

;; フレームの生成とパッケージシステムの初期化より前に評価される。
;; 見た目に関わる設定をここに置くのは、init.el でやると一度描画されたものを
;; 消すことになり、起動時にちらつくため。

;;; Code:

;; 起動中は GC を止めておく。閾値を戻す処理は init.el の最後にある。
;; 既定値のままだと起動処理の途中で何度も GC が走って遅い。
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; パッケージシステムの初期化は init.el で明示的に行う。
;; ここで走らせると use-package の設定より先に load-path が確定してしまう。
(setq package-enable-at-startup nil)

;; ファイル名の解決に使う正規表現を起動中だけ無効にする (init.el で戻す)。
(defvar i999rri--file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)

;; GUI 要素を作られる前に無効化する。terminal 版では元から出ないが、
;; GUI で開いたときのために入れておく。
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

(setq menu-bar-mode nil
      tool-bar-mode nil
      scroll-bar-mode nil)

;; 起動時のメッセージ類。init.el に書くと一瞬表示されてしまう。
(setq inhibit-startup-screen t
      inhibit-startup-message t
      inhibit-startup-echo-area-message user-login-name
      initial-scratch-message nil)

;; フレームのリサイズを避ける (起動が速くなる)。
(setq frame-inhibit-implied-resize t)

;; native compilation の警告はログに送るだけにする。
(setq native-comp-async-report-warnings-errors 'silent)

(provide 'early-init)
;;; early-init.el ends here
