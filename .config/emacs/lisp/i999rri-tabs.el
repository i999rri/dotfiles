;;; i999rri-tabs.el --- urusi-emacs のファイルのタブ -*- lexical-binding: t; -*-

;;; Commentary:

;; 各窓の上の段 (tab-line) に、ネイティブのタブを描く。どのバッファを並べるかは
;; init.el の tab-line の設定 (`tab-line-tabs-function') が決め、ここは見た目だけ。
;;
;; Visual Studio (2019 まで) のドキュメントタブの形にする。選択中のタブはオレンジで
;; 塗り (テーマの `tab-line-tab-current')、段の下にオレンジの線を横いっぱいに引く。
;; 塗ったタブと編集画面がこの線でつながり、どのタブを見ているかが形で分かる。
;;
;; 段の高さは Emacs が face `tab-line' から決める (テーマで 32px)。

;;; Code:

(require 'urusi-screen)
(require 'urusi-tabs)

(defvar i999rri-tabs-accent-thickness 2
  "段の下に引く線の太さ (XAML の単位)。")

(defun i999rri-tabs--color (face attribute)
  "FACE の ATTRIBUTE の色を XAML の形で返す。"
  (urusi-screen-color (face-attribute face attribute nil t)))

(defun i999rri-tabs-icon (tab)
  "TAB のバッファの種類のアイコン (nerd-icons)。色はタブの文字と同じにする。"
  ;; 種類ごとの色のままだと、オレンジに塗った選択中のタブの上で読めないものがある。
  ;; 形だけ借り、色は描く側でタブの文字の色にしてもらう
  (let ((buffer (let ((tab (plist-get tab :tab)))
                  (if (bufferp tab) tab (alist-get 'buffer tab)))))
    (when (and (buffer-live-p buffer) (require 'nerd-icons nil t))
      (let ((icon (with-current-buffer buffer (nerd-icons-icon-for-buffer))))
        (when (and (stringp icon) (< 0 (length icon)))
          (propertize (substring-no-properties icon)
                      'face `(:family ,nerd-icons-font-family)))))))

(setq urusi-tabs-icon-function #'i999rri-tabs-icon)

(defun i999rri-tab-line (window _line)
  "WINDOW のファイルのタブを、下にアクセントの線を引いた段として返す。"
  `(Border :BorderBrush ,(or (i999rri-tabs--color 'tab-line-tab-current :background)
                             "Transparent")
           :BorderThickness ,(format "0,0,0,%s" i999rri-tabs-accent-thickness)
           :Background ,(or (i999rri-tabs--color 'tab-line :background) "Transparent")
           ,(urusi-tabs (urusi-tabs-tab-line-tabs window))))

(provide 'i999rri-tabs)
;;; i999rri-tabs.el ends here
