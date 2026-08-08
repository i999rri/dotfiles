;;; init.el --- Emacs の設定 -*- lexical-binding: t; -*-

;;; Commentary:

;; nvim (lazy.nvim) 側と同じ構成を狙っている。向こうの lua/plugins/ にある
;; ものを一つずつ対応させた。
;;
;;   lazy.nvim              -> elpaca
;;   fzf-lua                -> vertico + consult + orderless + marginalia
;;   nvim-cmp               -> corfu + cape
;;   lspkind                -> kind-icons (corfu の :annotation)
;;   luasnip                -> tempel
;;   nvim-lspconfig, mason  -> eglot (同梱)
;;   nvim-treesitter        -> treesit (同梱)
;;   nvim-ts-autotag        -> sgml-electric-tag-pair-mode (同梱)
;;   ultimate-autopair      -> electric-pair-mode (同梱)
;;   conform                -> apheleia
;;   trouble                -> flymake + consult-flymake (同梱)
;;   toggleterm             -> eat
;;   (toggleterm 経由の lazygit) -> magit
;;   oil.nvim               -> dired (同梱)
;;   project.nvim           -> project.el (同梱)
;;   indent-blankline       -> indent-bars
;;   modes.nvim             -> (evil のカーソル色で代替)
;;   lualine                -> doom-modeline
;;   noice.nvim             -> vertico (ミニバッファ自体が置き換わる)
;;   vimade                 -> 入れない (GUI では画面が暗くなるのが煩わしい)
;;   neogen                 -> separedit + docstring は各 major-mode に任せる
;;   render-markdown        -> markdown-mode
;;   calendar.vim           -> calfw
;;   skkeleton              -> ddskk
;;   kulala                 -> verb
;;   snacks.nvim (dashboard) -> dashboard
;;     nvim 側は snacks 本体を有効にしたうえで dashboard だけ使い、bigfile /
;;     explorer / indent / input / picker / notifier / quickfile / scope /
;;     scroll / statuscolumn / words は明示的に切っている。Emacs 側も同じく
;;     起動画面だけを入れ、他は対応するものを個別に選んでいる。
;;   smear-cursor           -> 入れない (nvim 側も enabled=false)
;;
;; 揃えるのはプラグインの構成まで。キーバインドは Emacs の標準を壊さないように
;; しており、vim 化 (evil) はしていない。consult のように既存コマンドを置き換え
;; るものは README が薦める割り当てに従う。

;;; Code:

;;; ---------------------------------------------------------------------------
;;; elpaca (パッケージ管理)
;;; ---------------------------------------------------------------------------

;; ここは elpaca 同梱の doc/installer.el をそのまま貼っている。
;; 自分で書き換えるとディレクトリ構成や autoloads の読み込み方が本体と食い違う。
(defvar elpaca-installer-version 0.12)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-sources-directory (expand-file-name "sources/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca-activate)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-sources-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; use-package を elpaca と統合する。:ensure t で elpaca が取りに行く。
(elpaca elpaca-use-package
  (elpaca-use-package-mode))
(elpaca-wait)

(setq use-package-always-ensure t)

;;; ---------------------------------------------------------------------------
;;; 基本設定 (nvim の vim.opt 相当)
;;; ---------------------------------------------------------------------------

;; nvim: vim.opt.number = true
(setq display-line-numbers-type 'absolute)
(global-display-line-numbers-mode 1)

;; nvim: vim.opt.cursorline = true
(global-hl-line-mode 1)

;; カーソルを縦線にする。既定の box は 1 文字ぶんを塗りつぶし、その下の文字を
;; 反転させて表示するため、カーソルの乗っている文字が読みにくい。
;;
;; 幅は 2px。既定の bar は 1px で、15pt のフォントと line-spacing = 5 の行間に
;; 対しては細く、視線を戻したときに見つけにくい。
;;
;; 色は asiimov の cursor face (Ghostty の cursor-color = ff6b35 と同じ) が持つ。
(setq-default cursor-type '(bar . 2))

;; 選択していないウィンドウにはカーソルを出さない。既定では中抜きの箱が残るが、
;; 縦線にすると本物との差が細さの違いだけになり、今どこにいるのか読めなくなる。
(setq cursor-in-non-selected-windows nil)

;; nvim: vim.opt.autoread = true と checktime の autocmd
(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t
      auto-revert-verbose nil)

;; nvim: vim.opt.clipboard = "unnamedplus"
;; Windows でも WSL でも OS のクリップボードと共有する
(setq select-enable-clipboard t
      select-enable-primary nil)

;; nvim: ultimate-autopair 相当
(electric-pair-mode 1)

;; バッファを閉じたとき、その窓が直前に表示していたものへ戻る。
;;
;; 戻ること自体は Emacs の既定の動作で、窓ごとに持っている履歴
;; (window-prev-buffers) を遡っている。ただしそこには *Messages* や
;; *Flymake log* のような裏方も同じように積まれるため、遡るうちに開いた覚えの
;; ないバッファへ着地する。戻っていないように見えるのはこれが理由。
;;
;; 名前が * で始まるものを候補から外す。端末 (eat) と dashboard だけは自分で
;; 開くものなので残す。dashboard を残すと、実バッファを閉じ切ったときの
;; 落ち先がそこになり、起動直後と同じ画面に戻る。
;;
;; C-x <left> / <right> の行き先も同じ判定を使う。
(defun i999rri/prev-buffer-skip-p (_window buffer _bury-or-kill)
  "BUFFER が裏方なら non-nil を返し、戻り先の候補から外す。"
  (and (string-prefix-p "*" (buffer-name buffer))
       (not (memq (buffer-local-value 'major-mode buffer)
                  '(eat-mode dashboard-mode)))))

(setq switch-to-prev-buffer-skip #'i999rri/prev-buffer-skip-p)

;; 戻れるものが尽きたときは dashboard を出す。
;;
;; 上の判定にできるのは候補から外すことだけで、外し切って何も残らなかった場合は
;; Emacs 側の最後の受け皿が使われる。そこはこの判定を通らないため、結局 *Messages*
;; のような裏方に着地してしまう。
;;
;; そこで行き先が裏方だったときに限り dashboard へ差し替える。バッファが残って
;; いなければ組み立て直すので、一度閉じた後でも帰る場所ができる。
(defvar i999rri--dashboard-fallback-running nil
  "dashboard を組み立てている最中かどうか。")

(defun i999rri/dashboard-buffer ()
  "dashboard のバッファを返す。無ければ組み立て直す。"
  (when (and (bound-and-true-p dashboard-buffer-name)
             (fboundp 'dashboard-refresh-buffer))
    (or (get-buffer dashboard-buffer-name)
        ;; 組み立てると選択中のウィンドウに表示されてしまうため、元に戻す
        (save-window-excursion
          (dashboard-refresh-buffer)
          (get-buffer dashboard-buffer-name)))))

(defun i999rri/show-dashboard-in (window)
  "WINDOW が裏方を映しているなら dashboard に差し替える。"
  ;; 組み立て直すとき古いバッファを kill するため、その巻き添えでここが再び
  ;; 呼ばれる。組み立て中は入らない
  (unless (or i999rri--dashboard-fallback-running
              (not (window-live-p window))
              (window-minibuffer-p window)
              (window-dedicated-p window))
    (when (i999rri/prev-buffer-skip-p window (window-buffer window) nil)
      (let* ((i999rri--dashboard-fallback-running t)
             (buf (i999rri/dashboard-buffer)))
        (when (buffer-live-p buf)
          (set-window-buffer window buf))))))

;; 閉じたときの差し替えは、Emacs 30 では replace-buffer-in-windows が C 側にあり
;; Lisp の switch-to-prev-buffer を経由しない。そのため kill-buffer 自体を包んで、
;; そのバッファを映していた窓を閉じた後に見に行く。
;;
;; 窓の一覧は kill する前に取る。閉じた後では、どこに映っていたか辿れなくなる。
;;
;; dashboard 自身を閉じたときは何もしない。ここで出し直すと閉じられなくなる。
(defun i999rri/kill-buffer-to-dashboard (fn &optional buffer-or-name)
  "FN で BUFFER-OR-NAME を閉じ、映していた窓に戻り先が無ければ dashboard を出す。"
  (let* ((buf (if buffer-or-name (get-buffer buffer-or-name) (current-buffer)))
         ;; 起動の途中ではまだ dashboard が読まれておらず、この変数は nil。
         ;; get-buffer に nil を渡すと型エラーになるため、名前どうしで比べる
         (windows (and (buffer-live-p buf)
                       (not (equal (buffer-name buf)
                                   (bound-and-true-p dashboard-buffer-name)))
                       (get-buffer-window-list buf nil t)))
         (killed (funcall fn buffer-or-name)))
    (when killed
      (mapc #'i999rri/show-dashboard-in windows))
    killed))

(advice-add 'kill-buffer :around #'i999rri/kill-buffer-to-dashboard)

;; C-x <left> / <right> で辿り着いた先が裏方だった場合も同じ扱いにする。
;; こちらは Lisp から呼ばれるため、switch-to-prev-buffer を包めば足りる。
(defun i999rri/fall-back-to-dashboard (&optional window &rest _)
  "WINDOW の行き先が裏方しか残っていなければ dashboard に差し替える。"
  (i999rri/show-dashboard-in (or window (selected-window))))

(advice-add 'switch-to-prev-buffer :after #'i999rri/fall-back-to-dashboard)
(advice-add 'switch-to-next-buffer :after #'i999rri/fall-back-to-dashboard)

;; バックアップと自動保存を一箇所に集める。既定では編集中のファイルの隣に
;; 散らかるため、git の作業ツリーが汚れる。
(let ((dir (expand-file-name "var/" user-emacs-directory)))
  (setq backup-directory-alist `(("." . ,(expand-file-name "backup/" dir)))
        auto-save-file-name-transforms `((".*" ,(expand-file-name "auto-save/" dir) t))
        lock-file-name-transforms `((".*" ,(expand-file-name "lock/" dir) t))
        custom-file (expand-file-name "custom.el" dir)
        ;; 履歴の類も同じ場所にまとめる。既定では user-emacs-directory の
        ;; 直下に散らばり、設定ファイルと混ざる
        recentf-save-file (expand-file-name "recentf" dir)
        save-place-file (expand-file-name "places" dir)
        savehist-file (expand-file-name "history" dir)
        project-list-file (expand-file-name "projects" dir)
        transient-history-file (expand-file-name "transient/history.el" dir)
        transient-levels-file (expand-file-name "transient/levels.el" dir)
        transient-values-file (expand-file-name "transient/values.el" dir))
  (dolist (d '("backup/" "auto-save/" "lock/" "transient/"))
    (make-directory (expand-file-name d dir) t)))

;; custom-set-variables の書き込み先を分けたので、あれば読む。
(when (file-exists-p custom-file) (load custom-file nil t))

(setq-default indent-tabs-mode nil
              tab-width 4)

;; 質問を y/n に統一する。
(setq use-short-answers t)

;; 開いたファイルの履歴。dashboard の Recent Files と consult-recent-file が
;; これを見るため、有効にしないとどちらも常に空になる。
(use-package recentf
  :ensure nil
  :init (recentf-mode 1)
  :custom
  (recentf-max-saved-items 200)
  (recentf-auto-cleanup 'never)         ; 起動のたびに存在確認をすると遅い
  :config
  ;; elpaca が取得したパッケージや自動生成物は履歴に残さない
  (add-to-list 'recentf-exclude (expand-file-name "elpaca/" user-emacs-directory))
  (add-to-list 'recentf-exclude (expand-file-name "var/" user-emacs-directory)))

;; ファイル内のカーソル位置と、ミニバッファの入力履歴を残す。
(save-place-mode 1)
(savehist-mode 1)

;; terminal では親の端末の背景を透かし、GUI では背景色を持たせる。
;; nvim 側で guibg=none にしているのと同じ狙い。
;;
;; frame を引数に取って毎回判定するのが要点。daemon は GUI のない状態で
;; 起動するため、起動時に一度だけ判定すると「terminal である」と決まってしまい、
;; あとから emacsclient で開いた GUI フレームまで背景を失う。
(defun i999rri/apply-frame-background (&optional frame)
  "FRAME の背景を、terminal なら透過、GUI なら通常の色にする。"
  (let ((frame (or frame (selected-frame))))
    (set-face-background 'default
                         (if (display-graphic-p frame) "#1e1e1e" "unspecified-bg")
                         frame)))

(add-hook 'window-setup-hook #'i999rri/apply-frame-background)
(add-hook 'after-make-frame-functions #'i999rri/apply-frame-background)

;; フォント。Ghostty と nvim で使っているものに合わせる。
;;
;; Windows 版の Emacs は -nw だと Windows のコンソール API を直接叩くため、
;; ConPTY ベースの端末では initialize_w32_display に失敗する
;; ("GetConsoleScreenBufferInfo failed")。このため Windows では GUI で使う。
;; 本体のフォント指定は early-init.el にある (フレーム生成後に変えると
;; 初期サイズの指定が効かなくなるため)。ここでは日本語だけ同じ系列に揃える。
;; 指定しないと別のフォントが選ばれて行の高さがずれる。
(defconst i999rri/font-family "JetBrainsMono NFM"
  "使うフォント。Ghostty の font-family に対応する Windows 側の名前。")

(defun i999rri/setup-japanese-font (&optional frame)
  "FRAME の日本語フォントを本体と揃える。"
  (when (and (display-graphic-p frame)
             (member i999rri/font-family (font-family-list frame)))
    (set-fontset-font t 'japanese-jisx0208
                      (font-spec :family i999rri/font-family) frame)))

(add-hook 'window-setup-hook #'i999rri/setup-japanese-font)
(add-hook 'after-make-frame-functions #'i999rri/setup-japanese-font)

;; Ghostty の adjust-cell-height = 5 に相当する行間。
(setq-default line-spacing 5)

;; Ghostty は font-feature で dlig / liga / calt を切っている。Emacs 側も
;; 合字の合成を無効にして見え方を揃える。
;;
;; auto-composition-mode はバッファローカルなので、関数を呼んでも今のバッファ
;; にしか効かない。既定値の方を落とす。
(setq-default auto-composition-mode nil)

;; ウィンドウが画面に収まるよう高さだけ詰める。
;;
;; フォントを大きくしているため、early-init.el で指定した行数がそのままでは
;; 入らない環境がある。幅には触らない。
;;
;; 判定には display-pixel-height ではなく、今フレームが乗っているモニタの
;; workarea を使う。マルチモニタでは display-pixel-* が全体の矩形を返すため、
;; 実際に使える領域とずれる (ここでは 2 枚で 3840x1080、workarea は 1920x1044)。
(defun i999rri/fit-frame-height (&optional frame)
  "FRAME の高さを、乗っているモニタの作業領域に収まる範囲まで縮める。"
  (let ((frame (or frame (selected-frame))))
    (when (display-graphic-p frame)
      (let* ((workarea (alist-get 'workarea (frame-monitor-attributes frame)))
             ;; workarea は (x y width height)
             (usable (if workarea (nth 3 workarea) (display-pixel-height)))
             ;; タイトルバーと余白の分を引く
             (max-lines (/ (- usable 60) (frame-char-height frame))))
        (when (> (frame-height frame) max-lines)
          (set-frame-height frame max-lines))))))

;; window-setup-hook では frame の実寸がまだ確定しておらず、ここで縮めると
;; 幅まで巻き添えになる。描画が落ち着いてから一度だけ行う。
;;
;; daemon では起動時にフレームがないため、emacsclient が作るフレームにも
;; 同じ処理をかける。
(add-hook 'emacs-startup-hook
          (lambda () (run-with-idle-timer 0.1 nil #'i999rri/fit-frame-height)))
(add-hook 'after-make-frame-functions
          (lambda (frame)
            (run-with-idle-timer 0.1 nil #'i999rri/fit-frame-height frame)))

;;; ---------------------------------------------------------------------------
;;; 見た目
;;; ---------------------------------------------------------------------------

;; この設定ファイルが置かれているディレクトリ。
;;
;; user-emacs-directory は symlink を辿らないため使えない (Windows 側は
;; AppData\Roaming\.emacs.d から dotfiles にリンクしている)。また load-file-name
;; は評価される場所によって変わるので、ここで一度だけ確定させておく。
(defconst i999rri/config-directory
  (file-name-directory (file-truename (or load-file-name buffer-file-name)))
  "init.el が実際に置かれているディレクトリ。")

;; nvim の colors/asiimov.lua をそのまま写したテーマ。
(add-to-list 'custom-theme-load-path i999rri/config-directory)
(load-theme 'asiimov t)

(use-package which-key
  :ensure nil                           ; Emacs 30 に同梱
  :init (which-key-mode 1)
  :custom (which-key-idle-delay 0.4))

;; nvim: lualine
;;
;; ただし nvim 側は laststatus=0 でステータスラインを隠し、statusline を "─" に
;; している。Emacs で mode-line を完全に消すと現在のモードや位置が分からなく
;; なるため、行を細く保ったうえで内容を最小限にする。
(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :custom
  (doom-modeline-height 1)
  (doom-modeline-bar-width 3)
  (doom-modeline-buffer-encoding nil)
  ;; アイコンは Nerd Font があれば出せる。
  ;;
  ;; ここで (display-graphic-p) を書くと、daemon 起動時に nil で固定されて
  ;; GUI フレームでも出なくなる。フレームを作るたびに設定し直す。
  :config
  (defun i999rri/apply-modeline-icon (&optional frame)
    "FRAME が GUI ならモードラインのアイコンを出す。"
    (setq doom-modeline-icon (display-graphic-p (or frame (selected-frame)))))
  (add-hook 'window-setup-hook #'i999rri/apply-modeline-icon)
  (add-hook 'after-make-frame-functions #'i999rri/apply-modeline-icon))

;; nvim の vimade (フォーカスのない窓を薄くする) は入れていない。
;; auto-dim-other-buffers を試したが、GUI で他のウィンドウに移るたびに画面が
;; 暗くなるのが煩わしく、得られるものに見合わなかった。

;;; ---------------------------------------------------------------------------
;;; 起動画面 (snacks.nvim の dashboard 相当)
;;; ---------------------------------------------------------------------------

;; Emacs の dashboard は最近のファイルやプロジェクトを一覧で出し、番号キーで
;; そこへ直接飛ぶのが基本の使い方。nvim の snacks は「キー + ラベル」を縦に
;; 並べる形だが、一覧を捨ててボタンだけにすると起動直後に作業へ戻るという
;; dashboard 本来の役割が失われるため、こちらは Emacs 側の作法に寄せる。
;;
;; nvim 側のボタン (Find File / Recent Files / Config / Session / Lazy / Quit) は
;; 一覧に出ないものだけ navigator として残した。
(use-package dashboard
  :init (dashboard-setup-startup-hook)
  :custom
  ;; emacsclient で新しいフレームを開いたときにも出す。これがないと
  ;; dashboard-setup-startup-hook の判定から外れた場合に *scratch* になる
  (initial-buffer-choice (lambda () (get-buffer-create dashboard-buffer-name)))
  (dashboard-banner-logo-title "")
  ;; nvim 側は header が空なので、こちらもバナーを出さない。下の
  ;; dashboard-startupify-list から dashboard-insert-banner を外してあるため、
  ;; dashboard-startup-banner は評価されない。
  (dashboard-center-content t)
  (dashboard-vertically-center-content t)
  (dashboard-show-shortcuts t)          ; 番号キーで項目を開く
  (dashboard-set-footer nil)
  (dashboard-set-navigator t)
  ;; アイコンは使わない。GUI かどうかで切り替えることもできるが、daemon では
  ;; 起動時に判定できず (GUI がまだない)、フレームごとに読み直させるには
  ;; dashboard を作り直す必要があって割に合わない。
  (dashboard-set-heading-icons nil)
  (dashboard-set-file-icons nil)
  (dashboard-navigation-cycle t)
  (dashboard-projects-backend 'project-el)

  (dashboard-items '((recents  . 5)
                     (projects . 5)))

  ;; 何をどの順で描くかはこのリストで決まる。dashboard-set-navigator を立てる
  ;; だけではボタンは出ない (既定のリストに navigator が入っていないため)。
  (dashboard-startupify-list '(dashboard-insert-newline
                               dashboard-insert-items
                               dashboard-insert-newline
                               dashboard-insert-navigator
                               dashboard-insert-newline
                               dashboard-insert-init-info))
  :config
  ;; 一覧で辿れないものだけボタンにする。Recent Files と Restore Session は
  ;; 上の items で足りるため置いていない。
  (setq dashboard-navigator-buttons
        `((("" "Find File" "" (lambda (&rest _) (call-interactively #'find-file)) 'default)
           ("" "Config"    "" (lambda (&rest _)
                                 (let ((default-directory i999rri/config-directory))
                                   (call-interactively #'find-file)))
            'default)
           ("" "Packages"  "" (lambda (&rest _) (elpaca-manager)) 'default)
           ("" "Quit"      "" (lambda (&rest _) (save-buffers-kill-terminal)) 'default)))))

;;; ---------------------------------------------------------------------------
;;; 補完 UI (fzf-lua / snacks picker 相当)
;;; ---------------------------------------------------------------------------

(use-package vertico
  :init (vertico-mode 1)
  :custom (vertico-cycle t))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package marginalia
  :init (marginalia-mode 1))

;; キーは consult が README で薦めている割り当てに従う。既存のコマンドを
;; 置き換える形になっている (C-x b が switch-to-buffer から consult-buffer へ、
;; など) ので、Emacs の操作を覚えたまま使える。
;;
;; nvim 側の <C-l> (live_grep) を C-l に割り当てると Emacs の
;; recenter-top-bottom を潰すことになるため、search 系の M-s に置いている。
(use-package consult
  :bind
  (("C-x b"   . consult-buffer)         ; switch-to-buffer の置き換え
   ("C-x 4 b" . consult-buffer-other-window)
   ("C-x r b" . consult-bookmark)
   ("M-y"     . consult-yank-pop)       ; yank-pop の置き換え
   ("M-g g"   . consult-goto-line)      ; goto-line の置き換え
   ("M-g i"   . consult-imenu)
   ("M-g f"   . consult-flymake)        ; trouble 相当
   ("M-s r"   . consult-ripgrep)        ; nvim の live_grep
   ("M-s l"   . consult-line)
   ("M-s f"   . consult-find))
  :custom
  (consult-narrow-key "<"))

(use-package embark
  :bind ("C-." . embark-act))

(use-package embark-consult
  :after (embark consult))

;;; ---------------------------------------------------------------------------
;;; jump list (nvim の C-o / C-i 相当)
;;; ---------------------------------------------------------------------------

;; Emacs には「どの移動が jump か」という概念が無い。vim は gg や G、検索、タグ
;; ジャンプを本体が jump として扱うが、Emacs にあるのはマークリングだけで、積まれる
;; 条件も、前へ進む手段が無いことも vim とは違う。
;;
;; better-jumper が持っているのは箱と前後移動だけで、位置を積む処理は動かない。
;; evil を入れていれば evil-set-jump に相乗りするが、こちらは入れていないため
;; 「何を jump とみなすか」を下の advice で自分で決めている。
;;
;; 少なすぎると戻りたい所へ戻れず、多すぎると M-[ が細かく刻まれる。増減はここを
;; 触る。

;; better-jumper-set-jump は積む位置を引数に取れる。advice にそのまま渡すと元の
;; 関数の引数が位置として解釈されてしまうため、捨ててから呼ぶ。
(defun i999rri/set-jump (&rest _)
  "引数を無視して今の位置を jump list に積む。"
  (when (fboundp 'better-jumper-set-jump)
    (better-jumper-set-jump)))

(use-package better-jumper
  ;; :bind だけだとキーを押すまで読み込まれず、それまでの移動が積まれない
  :demand t
  :bind (("M-[" . better-jumper-jump-backward)    ; nvim: C-o
         ("M-]" . better-jumper-jump-forward)     ; nvim: C-i
         ;; 端末では M-[ が CSI (ESC [) の先頭と重なる。emacs -nw でも辿れるよう
         ;; 同じものを C-c 側にも置いておく
         ("C-c [" . better-jumper-jump-backward)
         ("C-c ]" . better-jumper-jump-forward))
  :config
  (better-jumper-mode 1)

  ;; 積む対象。vim が jump として扱うものに対応させている
  (dolist (cmd '(xref-find-definitions    ; タグジャンプ
                 xref-find-references
                 consult-line             ; 検索 (/ と n)
                 consult-ripgrep
                 consult-imenu
                 consult-goto-line        ; :123
                 consult-flymake
                 consult-buffer           ; ファイル間の移動
                 beginning-of-buffer      ; gg
                 end-of-buffer))          ; G
    (advice-add cmd :before #'i999rri/set-jump))

  ;; 素の検索は、始めた位置を積む
  (add-hook 'isearch-mode-hook #'i999rri/set-jump))

;;; ---------------------------------------------------------------------------
;;; インライン補完 (nvim-cmp 相当)
;;; ---------------------------------------------------------------------------

(use-package corfu
  :init (global-corfu-mode 1)
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.1)
  (corfu-auto-prefix 1)
  (corfu-cycle t)
  ;; terminal 版ではポップアップが描けないため、下の corfu-terminal に任せる
  (corfu-popupinfo-delay '(0.5 . 0.2)))

(use-package corfu-terminal
  :after corfu
  :config
  (unless (display-graphic-p)
    (corfu-terminal-mode 1)))

;; nvim の nvim-cmp は sources を
;;   1. skkeleton / nvim_lsp / luasnip / nvim_lua
;;   2. buffer (3 文字以上、表示中のバッファのみ) / path
;; の 2 段で引いている。前段が出たら後段は使わない。
;; Emacs の completion-at-point-functions は先頭から順に試すので、同じ並びにする。
(use-package cape
  :init
  ;; 後ろから足すと先頭に積まれるため、優先度の低いものから登録する
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-dabbrev)   ; buffer 相当
  :custom
  ;; nvim: keyword_length = 3
  (cape-dabbrev-min-length 3)
  ;; nvim: 表示中のバッファのみを対象にする
  (cape-dabbrev-check-other-buffers t))

;;; ---------------------------------------------------------------------------
;;; LSP (nvim-lspconfig + mason 相当)
;;; ---------------------------------------------------------------------------

;; eglot は Emacs 29 以降に同梱。mason に相当する「サーバーを自動で入れる」層は
;; ないので、言語サーバーは Nix や scoop 側で入れる。
(use-package eglot
  :ensure nil
  :hook ((prog-mode . eglot-ensure))
  :custom
  (eglot-autoshutdown t)
  (eglot-events-buffer-size 0))

;; nvim: vim.diagnostic.config({ virtual_text = true })
(use-package flymake
  :ensure nil
  :hook (prog-mode . flymake-mode))

;;; ---------------------------------------------------------------------------
;;; treesitter
;;; ---------------------------------------------------------------------------

(use-package treesit
  :ensure nil
  :custom
  ;; nvim: foldmethod=expr + nvim_treesitter#foldexpr()
  (treesit-font-lock-level 4))

;;; ---------------------------------------------------------------------------
;;; git (toggleterm + lazygit 相当)
;;; ---------------------------------------------------------------------------

;; magit は transient >= 0.13 を要求するが、Emacs に同梱されているものはそれより
;; 古い。パッケージマネージャは組み込みを自動では置き換えないため、magit より先に
;; 明示的に取得しておく必要がある。これがないと
;; "Symbol's function definition is void: transient-define-group" で読み込めない。
(use-package transient)

(use-package magit
  :after transient
  ;; nvim: <Leader>k で lazygit
  :bind ("C-c g" . magit-status)
  :custom
  (magit-diff-refine-hunk 'all))

;;; ---------------------------------------------------------------------------
;;; フォーマット (conform 相当)
;;; ---------------------------------------------------------------------------

(use-package apheleia
  :init (apheleia-global-mode 1))

;;; ---------------------------------------------------------------------------
;;; 見た目の補助
;;; ---------------------------------------------------------------------------

;; nvim: indent-blankline
(use-package indent-bars
  :hook (prog-mode . indent-bars-mode)
  :custom
  (indent-bars-treesit-support t)
  (indent-bars-no-descend-string t))

;;; ---------------------------------------------------------------------------
;;; スニペット (luasnip 相当)
;;; ---------------------------------------------------------------------------

(use-package tempel
  :bind (("M-+" . tempel-complete)
         ("M-*" . tempel-insert)))

;;; ---------------------------------------------------------------------------
;;; 日本語入力 (skkeleton 相当)
;;; ---------------------------------------------------------------------------

;; nvim 側は denops + skkeleton。Emacs では ddskk が同じ SKK 方式。
;; 辞書は初回起動時に取得を促されるため、必要になってから設定する。
;;
;; C-x C-j は SKK の慣習だが、Emacs では dired-jump の既定でもある。日本語入力の
;; 方が使う頻度が高いため SKK に譲り、dired へは C-x d から入る。
(use-package ddskk
  :bind ("C-x C-j" . skk-mode)
  :custom
  (skk-egg-like-newline t)
  (skk-show-annotation nil))

;;; ---------------------------------------------------------------------------
;;; ターミナル (toggleterm 相当)
;;; ---------------------------------------------------------------------------

;; nvim 側は <C-t> で float のターミナルを開く。Emacs には組み込みの term/shell も
;; あるが、eat は端末エミュレーションが素直で、terminal 版でもそのまま動く。
(use-package eat
  :bind ("C-c t" . eat)
  :custom
  (eat-kill-buffer-on-exit t))         ; nvim: close_on_exit = true

;;; ---------------------------------------------------------------------------
;;; markdown (render-markdown 相当)
;;; ---------------------------------------------------------------------------

(use-package markdown-mode
  :mode ("\\.md\\'" "\\.mdx\\'")
  :custom
  (markdown-fontify-code-blocks-natively t)
  (markdown-hide-markup nil))

;;; ---------------------------------------------------------------------------
;;; カレンダー (calendar.vim 相当)
;;; ---------------------------------------------------------------------------

;; nvim 側は Google カレンダー / タスクと連携させている。calfw も同じ位置づけの
;; もので、org や ical を取り込める。
(use-package calfw
  :bind ("C-c a" . cfw:open-calendar-buffer))

(use-package calfw-org
  :after calfw)

;;; ---------------------------------------------------------------------------
;;; タグの自動補完 (nvim-ts-autotag 相当)
;;; ---------------------------------------------------------------------------

;; HTML/JSX で開始タグを閉じたときに終了タグを作る。Emacs は sgml-mode に同等の
;; 機能を持っているため、外部パッケージは要らない。
(add-hook 'sgml-mode-hook #'sgml-electric-tag-pair-mode)
(add-hook 'html-mode-hook #'sgml-electric-tag-pair-mode)
(add-hook 'mhtml-mode-hook #'sgml-electric-tag-pair-mode)

;;; ---------------------------------------------------------------------------
;;; REST クライアント (kulala 相当)
;;; ---------------------------------------------------------------------------

(use-package verb
  :config
  (with-eval-after-load 'org
    (define-key org-mode-map (kbd "C-c C-r") verb-command-map)))

;;; ---------------------------------------------------------------------------
;;; ファイラ (oil.nvim 相当)
;;; ---------------------------------------------------------------------------

(use-package dired
  :ensure nil
  :custom
  (dired-listing-switches "-alh --group-directories-first")
  ;; 開くたびにバッファが増えるのを避ける
  (dired-kill-when-opening-new-dired-buffer t))

;;; ---------------------------------------------------------------------------
;;; プロジェクト (project.nvim 相当)
;;; ---------------------------------------------------------------------------

;; project.el は C-x p を prefix として持っている (C-x p f でファイル検索、
;; C-x p p でプロジェクト切り替え、C-x p g で grep)。標準のままで nvim の
;; <Leader>p / <C-p> に相当する操作ができるため、独自の割り当ては足さない。
(use-package project
  :ensure nil)

;;; ---------------------------------------------------------------------------
;;; 後始末
;;; ---------------------------------------------------------------------------

;; early-init.el で外していたものを戻す。ここでやらないと GC が走らなくなり、
;; 長時間使ったときにメモリを掴んだままになる。
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 32 1024 1024)
                  gc-cons-percentage 0.1
                  file-name-handler-alist i999rri--file-name-handler-alist)
            (message "起動 %.2f 秒 / GC %d 回"
                     (float-time (time-subtract after-init-time before-init-time))
                     gcs-done)))

(provide 'init)
;;; init.el ends here
