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

;; Ghostty の window-padding-x / window-padding-y = 0 に合わせて余白を作らない。
;; 背景色も先に入れておく。init.el でテーマを読むまでの間、既定の白い矩形が
;; 一瞬見えるのを防ぐ (Ghostty の background = 1e1e1e と同じ値)。
(push '(internal-border-width . 0) default-frame-alist)
(push '(background-color . "#1e1e1e") default-frame-alist)
(push '(foreground-color . "#e0e0e0") default-frame-alist)

;; フォント。大きさは .config/ghostty/config の font-size = 15 に合わせている。
;;
;; ここで指定するのは、フレームが作られた後に変えると桁数・行数が変わって
;; しまうため。ウィンドウのピクセル寸法は保たれる一方、1 文字の大きさが増える
;; ぶん収まる文字数が減り、下で指定するサイズが無視されたように見える。
;;
;; 太さは指定しない。ghostty 側は
;;   font-family = "JetBrainsMono Nerd Font Mono Bold"
;; と書いているが、この名前のファミリは存在せず (Windows にあるのは
;; "JetBrainsMono NFM" で、Bold はその中のウェイト)、実際には解決できていない。
;; また地の文を太字にすると、asiimov が Keyword や Function に付けている bold の
;; 強調が効かなくなる。
(push '(font . "JetBrainsMono NFM-15") default-frame-alist)

;; ウィンドウの初期サイズ。単位は行と桁で、実寸は上のフォントで決まる。
;; 80 桁のコードを開いて、横に補完やヘルプを出せる程度の幅にしてある。
;; フォントを 15pt にしているため、桁数の割に実寸は大きくなる。
;;
;; 画面に対して大きすぎる場合は起動後に高さだけ詰める (init.el の後半)。
(push '(width . 118) default-frame-alist)
(push '(height . 34) default-frame-alist)

;; 背景を少し透かす。
;;
;; Emacs にはウィンドウ全面に画像を敷く機能がないため、Ghostty の
;; background-image / background-image-opacity はそのままは再現できない。
;; 近いものとして背景自体を半透明にし、後ろの壁紙を透かす。
;;
;; alpha ではなく alpha-background を使うのは、前者だと文字まで透けるため。
(push '(alpha-background . 85) default-frame-alist)

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
