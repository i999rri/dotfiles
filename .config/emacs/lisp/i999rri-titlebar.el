;;; i999rri-titlebar.el --- urusi-emacs のタイトルバー -*- lexical-binding: t; -*-

;;; Commentary:

;; urusi-emacs の窓のタイトルバー。タイトルの文字は出さず、右端の最小化・
;; 最大化・閉じるのボタン (urusi-titlebar の部品) の左に、今いるプロジェクト
;; の名前を札のように出す (Visual Studio のタイトルバーと同じ形)。
;;
;; urusi-titlebar という名前の要素が、ドラッグで窓を動かせる領域になる。
;; 上に置いたボタンなどはそのまま押せるので、ここに何を足してもいい。

;;; Code:

(require 'color)
(require 'project)
(require 'urusi-screen)
(require 'urusi-titlebar)

(defface i999rri-titlebar
  '((t :inherit default))
  "タイトルバーの face。背景がバーの色、前景が文字とボタンの記号の色。"
  :group 'urusi)

(defvar i999rri-titlebar-height 32
  "タイトルバーの高さ (XAML の単位)。Windows 標準と同じ。")

(defvar i999rri-titlebar-project-lighten 8
  "プロジェクト名の札の背景を、バーの背景より何パーセント明るくするか。")

(defun i999rri-titlebar--color (attribute frame)
  "FRAME での `i999rri-titlebar' の ATTRIBUTE の色を XAML の形で返す。"
  (urusi-screen-color (face-attribute 'i999rri-titlebar attribute frame t)))

(defvar i999rri-titlebar--projects (make-hash-table :test #'equal)
  "ディレクトリごとの、そこが属するプロジェクトの名前 (無ければ `none')。
タイトルバーは描き直すたびに作るので、そのたびにファイルシステムを調べ
直さないよう覚えておく。")

(defun i999rri-titlebar--project-name (frame)
  "FRAME で選んでいるウィンドウのバッファが属するプロジェクトの名前を返す。
プロジェクトに属していなければ nil。"
  (let* ((buffer (window-buffer (frame-selected-window frame)))
         (directory (buffer-local-value 'default-directory buffer))
         (known (and directory (gethash directory i999rri-titlebar--projects))))
    (unless known
      (setq known (or (and directory
                           (with-current-buffer buffer
                             (when-let* ((project (project-current nil)))
                               (project-name project))))
                      'none))
      (when directory
        (puthash directory known i999rri-titlebar--projects)))
    (unless (eq known 'none) known)))

(defun i999rri-titlebar--project (frame background foreground)
  "FRAME のプロジェクト名の札を返す。プロジェクトが無ければ何も並べない。
札の背景は BACKGROUND より少し明るくし、文字は FOREGROUND で書く。
札だけで 1 行にしておき、名前が変わったときに送り直すのを札だけにする。"
  (let ((name (i999rri-titlebar--project-name frame)))
    `(Rows :key "i999rri-titlebar-project" :panel "StackPanel"
           :Grid.Column 1
           :VerticalAlignment "Center"
           :Margin "0,0,8,0"
           ,@(when name
               `((Border :key "project"
                         :CornerRadius 4
                         :Padding "10,3,10,4"
                         ,@(when background
                             `(:Background ,(urusi-screen-color
                                             (color-lighten-name
                                              background i999rri-titlebar-project-lighten))))
                         (TextBlock :Text ,name
                                    :FontSize 12
                                    ,@(when foreground `(:Foreground ,foreground)))))))))

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
            (ColumnDefinition :Width "Auto")
            (ColumnDefinition :Width "Auto"))
           ,(i999rri-titlebar--project frame background foreground)
           ,(urusi-titlebar-buttons :Grid.Column 2
                                    :height i999rri-titlebar-height
                                    :foreground foreground))))

(provide 'i999rri-titlebar)
;;; i999rri-titlebar.el ends here
