;;; init.el --- Emacs の設定 -*- lexical-binding: t; -*-

;;; Commentary:

;; nvim (lazy.nvim) 側と同じ構成を狙っている。対応は以下のとおり。
;;
;;   lazy.nvim              -> elpaca
;;   fzf-lua / snacks       -> vertico + consult + orderless + marginalia
;;   nvim-cmp / lspkind     -> corfu + cape
;;   nvim-lspconfig / mason -> eglot (組み込み)
;;   nvim-treesitter        -> treesit (組み込み)
;;   toggleterm + lazygit   -> magit
;;   trouble                -> flymake + consult-flymake
;;   conform                -> apheleia
;;   oil.nvim               -> dired (組み込み)
;;   project.nvim           -> project.el (組み込み)
;;   indent-blankline       -> indent-bars
;;   luasnip                -> tempel
;;   skkeleton              -> ddskk
;;   kulala                 -> verb
;;   ultimate-autopair      -> electric-pair-mode (組み込み)
;;
;; キーバインドは evil で vim に寄せている。leader も nvim と同じ Space。

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

;; nvim の asiimov (オレンジ #ff6b35 + ダーク) に寄せる。組み込みテーマを土台に
;; アクセントだけ合わせているので、外部テーマへの依存がない。
(load-theme 'modus-vivendi t)

(custom-set-faces
 '(hl-line ((t (:background "#2a2a2a"))))
 '(region ((t (:background "#3f3f4f"))))
 '(cursor ((t (:background "#ff6b35"))))
 '(mode-line ((t (:background "#1e1e1e" :foreground "#e0e0e0"))))
 '(mode-line-inactive ((t (:background "#1e1e1e" :foreground "#6e6e6e")))))

(use-package which-key
  :ensure nil                           ; Emacs 30 に同梱
  :init (which-key-mode 1)
  :custom (which-key-idle-delay 0.4))

;;; ---------------------------------------------------------------------------
;;; evil (vim のキーバインド)
;;; ---------------------------------------------------------------------------

(use-package evil
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil        ; evil-collection に任せる
        evil-want-C-u-scroll t
        evil-undo-system 'undo-redo
        ;; nvim 側で virtualedit=onemore にしているのと同じ狙い
        evil-move-beyond-eol t
        evil-move-cursor-back nil)
  :config
  (evil-mode 1)

  ;; nvim: <C-j><C-k> で Esc
  ;;
  ;; 逆順の C-k C-j は登録しない。Emacs では C-k が kill-line に割り当たって
  ;; いて prefix ではないため、その先に別のキーを繋げられない
  ;; ("Key sequence C-k C-j starts with non-prefix key C-k")。
  ;; insert state で C-k を潰してまで両順序に対応する価値はないと判断した。
  (evil-define-key 'insert 'global (kbd "C-j C-k") #'evil-normal-state)

  ;; nvim: 誤操作を避けるため p / q / Q / @ を無効化
  (evil-define-key 'normal 'global (kbd "p") #'ignore)
  (evil-define-key 'normal 'global (kbd "q") #'ignore)
  (evil-define-key 'normal 'global (kbd "Q") #'ignore)
  (evil-define-key 'normal 'global (kbd "@") #'ignore))

(use-package evil-collection
  :after evil
  :config (evil-collection-init))

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

(use-package consult
  :bind
  (;; nvim: <Leader><tab> でバッファ一覧
   ("C-c b" . consult-buffer)
   ;; nvim: <C-l> で live_grep
   ("C-l" . consult-ripgrep)
   ;; trouble 相当
   ("C-c d" . consult-flymake))
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

(use-package cape
  :init
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-dabbrev))

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
(use-package ddskk
  :bind ("C-x C-j" . skk-mode)
  :custom
  (skk-egg-like-newline t)
  (skk-show-annotation nil))

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

(use-package project
  :ensure nil
  :bind
  (;; nvim: <Leader>p / <C-p> でファイル検索
   ("C-c p" . project-find-file)
   ("C-x p" . project-switch-project)))

;;; ---------------------------------------------------------------------------
;;; leader キー (nvim と同じ Space)
;;; ---------------------------------------------------------------------------

(with-eval-after-load 'evil
  (evil-define-key 'normal 'global (kbd "SPC p") #'project-find-file)
  (evil-define-key 'normal 'global (kbd "SPC k") #'magit-status)
  (evil-define-key 'normal 'global (kbd "SPC <tab>") #'consult-buffer)
  (evil-define-key 'normal 'global (kbd "SPC f") #'consult-ripgrep)
  (evil-define-key 'normal 'global (kbd "SPC d") #'consult-flymake)
  (evil-define-key 'normal 'global (kbd "SPC e") #'dired-jump))

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
