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
;;   vimade                 -> auto-dim-other-buffers
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

;; バックアップと自動保存を一箇所に集める。既定では編集中のファイルの隣に
;; 散らかるため、git の作業ツリーが汚れる。
(let ((dir (expand-file-name "var/" user-emacs-directory)))
  (setq backup-directory-alist `(("." . ,(expand-file-name "backup/" dir)))
        auto-save-file-name-transforms `((".*" ,(expand-file-name "auto-save/" dir) t))
        lock-file-name-transforms `((".*" ,(expand-file-name "lock/" dir) t))
        custom-file (expand-file-name "custom.el" dir))
  (dolist (d '("backup/" "auto-save/" "lock/"))
    (make-directory (expand-file-name d dir) t)))

;; custom-set-variables の書き込み先を分けたので、あれば読む。
(when (file-exists-p custom-file) (load custom-file nil t))

(setq-default indent-tabs-mode nil
              tab-width 4)

;; 質問を y/n に統一する。
(setq use-short-answers t)

;; terminal 版で親の端末の背景を透かす。nvim 側で guibg=none にしているのと同じ狙い。
(defun i999rri/unset-terminal-background (&optional frame)
  "FRAME が terminal なら背景色を指定しない状態にする。"
  (unless (display-graphic-p frame)
    (set-face-background 'default "unspecified-bg" frame)))
(add-hook 'window-setup-hook #'i999rri/unset-terminal-background)
(add-hook 'after-make-frame-functions #'i999rri/unset-terminal-background)

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
  (doom-modeline-icon nil))            ; terminal では表示が崩れるため使わない

;; nvim: vimade (フォーカスのない窓を薄くする)
(use-package auto-dim-other-buffers
  :init (auto-dim-other-buffers-mode 1)
  :custom (auto-dim-other-buffers-dim-on-focus-out t))

;;; ---------------------------------------------------------------------------
;;; 起動画面 (snacks.nvim の dashboard 相当)
;;; ---------------------------------------------------------------------------

;; nvim 側のボタン構成をそのまま写す。
;;   f Find File / r Recent Files / c Config / s Restore Session
;;   L Lazy (パッケージ管理) / q Quit
(use-package dashboard
  :init (dashboard-setup-startup-hook)
  :custom
  (dashboard-banner-logo-title "")
  ;; nvim 側は header が空なので、こちらもバナーを出さない。下の
  ;; dashboard-startupify-list から dashboard-insert-banner を外してあるため、
  ;; dashboard-startup-banner は評価されない。
  (dashboard-center-content t)
  (dashboard-vertically-center-content t)
  (dashboard-show-shortcuts t)
  (dashboard-set-footer nil)
  (dashboard-set-navigator t)
  (dashboard-set-heading-icons nil)     ; terminal ではアイコンを使わない
  (dashboard-set-file-icons nil)
  (dashboard-items nil)                 ; 一覧ではなくボタンだけを出す
  (dashboard-navigation-cycle t)

  ;; 何をどの順で描くかはこのリストで決まる。dashboard-set-navigator を立てる
  ;; だけではボタンは出ない (既定のリストに navigator が入っていないため)。
  ;; nvim 側の header が空でボタンだけ並ぶ形に合わせて、必要なものだけ残す。
  (dashboard-startupify-list '(dashboard-insert-newline
                               dashboard-insert-navigator
                               dashboard-insert-newline
                               dashboard-insert-init-info))
  :config
  ;; snacks の keys に相当するもの。dashboard 側に同等の仕組みがないため、
  ;; navigator として並べる。
  (setq dashboard-navigator-buttons
        `((("" "Find File"        "" (lambda (&rest _) (project-find-file)) 'default)
           ("" "Recent Files"     "" (lambda (&rest _) (consult-recent-file)) 'default)
           ("" "Config"           "" (lambda (&rest _)
                                        (let ((default-directory user-emacs-directory))
                                          (call-interactively #'find-file)))
            'default))
          (("" "Restore Session"  "" (lambda (&rest _) (desktop-read)) 'default)
           ("" "Packages"         "" (lambda (&rest _) (elpaca-manager)) 'default)
           ("" "Quit"             "" (lambda (&rest _) (save-buffers-kill-terminal)) 'default)))))

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
