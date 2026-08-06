;;; asiimov-theme.el --- CS:GO Asiimov 風のダークテーマ -*- lexical-binding: t; -*-

;;; Commentary:

;; nvim 側の colors/asiimov.lua を Emacs に写したもの。パレットと各要素への
;; 割り当ては向こうに合わせてある。
;;
;; terminal で使うとき背景色は指定しない。端末側の背景を透かすためで、
;; nvim 側で Normal の guibg を none にしているのと同じ狙い。

;;; Code:

(deftheme asiimov "CS:GO Asiimov 風のダークテーマ")

(let* ((white        "#e0e0e0")
       (black        "#1e1e1e")
       (grey         "#9e9e9e")
       (light-grey   "#6e6e6e")
       (dark-grey    "#2a2a2a")

       (orange       "#ff6b35")
       (light-orange "#ff8c61")
       (dark-orange  "#e55a2b")
       (yellow-orange "#ff9800")

       (blue         "#42a5f5")
       (green        "#66bb6a")
       (red          "#f44336")
       (purple       "#ba68c8")
       (cyan         "#26c6da")

       (bg     black)
       (fg     white)
       (comment grey)
       ;; 少し明るいグレー。nvim 側で MatchParen や Pmenu の背景に使っている
       (grey-3 "#3a3a3a")

       ;; terminal では背景を指定せず端末側を透かす
       (bg-or-none (if (display-graphic-p) black 'unspecified)))

  (custom-theme-set-faces
   'asiimov

   ;; 基本 UI
   `(default          ((t (:foreground ,fg :background ,bg-or-none))))
   `(cursor           ((t (:background ,orange))))
   `(hl-line          ((t (:background ,dark-grey))))
   `(line-number      ((t (:foreground ,light-grey :background ,bg-or-none))))
   `(line-number-current-line ((t (:foreground ,orange :weight bold :background ,bg-or-none))))
   `(fringe           ((t (:background ,bg-or-none))))
   `(vertical-border  ((t (:foreground ,dark-grey))))
   `(fill-column-indicator ((t (:foreground ,dark-grey))))

   ;; 選択・検索
   `(region           ((t (:foreground ,white :background ,orange))))
   `(highlight        ((t (:foreground ,black :background ,orange))))
   `(isearch          ((t (:foreground ,white :background ,orange))))
   `(lazy-highlight   ((t (:foreground ,white :background ,dark-orange))))
   `(match            ((t (:foreground ,orange :weight bold))))

   ;; モードライン (nvim の StatusLine に対応)
   `(mode-line          ((t (:foreground ,black :background ,orange))))
   `(mode-line-inactive ((t (:foreground ,grey  :background ,dark-grey))))
   `(mode-line-buffer-id ((t (:weight bold))))

   ;; タブ (nvim の TabLine)
   `(tab-bar          ((t (:foreground ,grey  :background ,dark-grey))))
   `(tab-bar-tab      ((t (:foreground ,black :background ,orange))))
   `(tab-bar-tab-inactive ((t (:foreground ,grey :background ,dark-grey))))

   ;; 補完のポップアップ (nvim の Pmenu)
   `(corfu-default    ((t (:foreground ,fg    :background ,dark-grey))))
   `(corfu-current    ((t (:foreground ,black :background ,orange))))
   `(corfu-bar        ((t (:background ,orange))))
   `(corfu-border     ((t (:background ,grey-3))))

   ;; vertico / consult の選択行 (nvim の TelescopeSelection)
   `(vertico-current  ((t (:foreground ,black :background ,orange :extend t))))
   `(completions-common-part ((t (:foreground ,orange :weight bold))))
   `(orderless-match-face-0 ((t (:foreground ,orange :weight bold))))
   `(orderless-match-face-1 ((t (:foreground ,blue   :weight bold))))
   `(orderless-match-face-2 ((t (:foreground ,green  :weight bold))))
   `(orderless-match-face-3 ((t (:foreground ,purple :weight bold))))

   ;; エラー・警告
   `(error            ((t (:foreground ,red :weight bold))))
   `(warning          ((t (:foreground ,yellow-orange :weight bold))))
   `(success          ((t (:foreground ,green))))

   ;; 構文
   `(font-lock-comment-face       ((t (:foreground ,comment :slant italic))))
   `(font-lock-comment-delimiter-face ((t (:foreground ,comment))))
   `(font-lock-doc-face           ((t (:foreground ,comment :slant italic))))
   `(font-lock-string-face        ((t (:foreground ,green))))
   `(font-lock-constant-face      ((t (:foreground ,orange))))
   `(font-lock-number-face        ((t (:foreground ,orange))))
   `(font-lock-variable-name-face ((t (:foreground ,fg))))
   `(font-lock-function-name-face ((t (:foreground ,blue :weight bold))))
   `(font-lock-keyword-face       ((t (:foreground ,orange :weight bold))))
   `(font-lock-builtin-face       ((t (:foreground ,orange))))
   `(font-lock-type-face          ((t (:foreground ,blue :weight bold))))
   `(font-lock-preprocessor-face  ((t (:foreground ,purple))))
   `(font-lock-operator-face      ((t (:foreground ,grey))))
   `(font-lock-delimiter-face     ((t (:foreground ,grey))))
   `(font-lock-warning-face       ((t (:foreground ,red :weight bold))))
   `(font-lock-negation-char-face ((t (:foreground ,light-orange))))

   ;; Emacs 29 以降で増えた分。指定しないと既定色のまま残り、他と揃わない。
   ;; nvim 側の対応は Delimiter / SpecialChar / Identifier あたり。
   `(font-lock-punctuation-face       ((t (:foreground ,grey))))
   `(font-lock-bracket-face           ((t (:foreground ,grey))))
   `(font-lock-misc-punctuation-face  ((t (:foreground ,grey))))
   `(font-lock-escape-face            ((t (:foreground ,light-orange))))
   `(font-lock-regexp-face            ((t (:foreground ,green))))
   `(font-lock-regexp-grouping-backslash ((t (:foreground ,light-orange))))
   `(font-lock-regexp-grouping-construct ((t (:foreground ,light-orange))))
   `(font-lock-property-name-face     ((t (:foreground ,fg))))
   `(font-lock-property-use-face      ((t (:foreground ,fg))))
   `(font-lock-variable-use-face      ((t (:foreground ,fg))))
   `(font-lock-function-call-face     ((t (:foreground ,blue))))
   `(font-lock-doc-markup-face        ((t (:foreground ,purple))))

   `(show-paren-match ((t (:foreground ,orange :background ,grey-3 :weight bold))))
   `(show-paren-mismatch ((t (:foreground ,white :background ,red :weight bold))))

   ;; 端末やコンパイル結果の出力に使われる 16 色。既定のままだと red3 や blue2
   ;; といったパレット外の色が混ざる。
   `(ansi-color-black          ((t (:foreground ,black      :background ,black))))
   `(ansi-color-red            ((t (:foreground ,red        :background ,red))))
   `(ansi-color-green          ((t (:foreground ,green      :background ,green))))
   `(ansi-color-yellow         ((t (:foreground ,yellow-orange :background ,yellow-orange))))
   `(ansi-color-blue           ((t (:foreground ,blue       :background ,blue))))
   `(ansi-color-magenta        ((t (:foreground ,purple     :background ,purple))))
   `(ansi-color-cyan           ((t (:foreground ,cyan       :background ,cyan))))
   `(ansi-color-white          ((t (:foreground ,white      :background ,white))))
   `(ansi-color-bright-black   ((t (:foreground ,light-grey :background ,light-grey))))
   `(ansi-color-bright-red     ((t (:foreground ,red        :background ,red))))
   `(ansi-color-bright-green   ((t (:foreground ,green      :background ,green))))
   `(ansi-color-bright-yellow  ((t (:foreground ,orange     :background ,orange))))
   `(ansi-color-bright-blue    ((t (:foreground ,blue       :background ,blue))))
   `(ansi-color-bright-magenta ((t (:foreground ,purple     :background ,purple))))
   `(ansi-color-bright-cyan    ((t (:foreground ,cyan       :background ,cyan))))
   `(ansi-color-bright-white   ((t (:foreground ,white      :background ,white))))

   ;; diff (nvim の DiffAdd 等)
   `(diff-added       ((t (:foreground ,green         :background "#1a3a1a"))))
   `(diff-changed     ((t (:foreground ,yellow-orange :background "#3a2a1a"))))
   `(diff-removed     ((t (:foreground ,red           :background "#3a1a1a"))))
   `(diff-refine-added   ((t (:foreground ,black :background ,green))))
   `(diff-refine-removed ((t (:foreground ,black :background ,red))))

   ;; magit (nvim の GitGutter 相当も兼ねる)
   `(magit-diff-added           ((t (:foreground ,green :background "#1a3a1a"))))
   `(magit-diff-removed         ((t (:foreground ,red   :background "#3a1a1a"))))
   `(magit-diff-added-highlight   ((t (:foreground ,green :background "#1a3a1a" :weight bold))))
   `(magit-diff-removed-highlight ((t (:foreground ,red   :background "#3a1a1a" :weight bold))))
   `(magit-section-heading      ((t (:foreground ,orange :weight bold))))
   `(magit-branch-local         ((t (:foreground ,blue))))
   `(magit-branch-remote        ((t (:foreground ,green))))
   `(magit-hash                 ((t (:foreground ,grey))))

   ;; 診断 (nvim の LspDiagnostics)
   `(flymake-error   ((t (:underline (:style wave :color ,red)))))
   `(flymake-warning ((t (:underline (:style wave :color ,yellow-orange)))))
   `(flymake-note    ((t (:underline (:style wave :color ,blue)))))

   ;; dired (nvim の NvimTree)
   `(dired-directory ((t (:foreground ,blue :weight bold))))
   `(dired-symlink   ((t (:foreground ,cyan))))

   ;; インデント線 (nvim の IblIndent / IblScope)
   `(indent-bars-face         ((t (:foreground ,grey-3))))
   `(indent-bars-current-face ((t (:foreground ,orange))))

   ;; which-key
   `(which-key-key-face            ((t (:foreground ,orange :weight bold))))
   `(which-key-group-description-face ((t (:foreground ,blue))))
   `(which-key-command-description-face ((t (:foreground ,fg))))

   ;; dashboard
   `(dashboard-heading ((t (:foreground ,orange :weight bold))))
   `(dashboard-items-face ((t (:foreground ,fg))))
   `(dashboard-banner-logo-title ((t (:foreground ,orange :weight bold))))

   ;; minibuffer
   `(minibuffer-prompt ((t (:foreground ,orange :weight bold))))

   ;; 補完の注釈まわり。既定のままだと色が付かず、候補と区別できない
   `(completions-annotations     ((t (:foreground ,comment :slant italic))))
   `(completions-first-difference ((t (:foreground ,orange :weight bold))))
   `(corfu-annotations           ((t (:foreground ,comment))))
   `(corfu-deprecated            ((t (:foreground ,light-grey :strike-through t))))
   `(marginalia-file-name        ((t (:foreground ,comment))))
   `(marginalia-documentation    ((t (:foreground ,comment :slant italic))))
   `(marginalia-size             ((t (:foreground ,blue))))
   `(marginalia-date             ((t (:foreground ,green))))
   `(marginalia-key              ((t (:foreground ,orange))))
   `(consult-file                ((t (:foreground ,fg))))
   `(consult-line-number         ((t (:foreground ,light-grey))))

   ;; 汎用の UI 要素。escape-glyph などは既定が cyan でパレットから外れる
   `(shadow              ((t (:foreground ,light-grey))))
   `(link                ((t (:foreground ,blue :underline t))))
   `(link-visited        ((t (:foreground ,purple :underline t))))
   `(button              ((t (:foreground ,blue :underline t))))
   `(escape-glyph        ((t (:foreground ,light-orange))))
   `(homoglyph           ((t (:foreground ,light-orange))))
   `(isearch-fail        ((t (:foreground ,white :background ,red))))
   `(secondary-selection ((t (:background ,grey-3))))
   `(trailing-whitespace ((t (:background ,red))))
   `(header-line         ((t (:foreground ,grey :background ,dark-grey))))
   `(tooltip             ((t (:foreground ,fg :background ,dark-grey))))
   `(help-key-binding    ((t (:foreground ,orange :background ,dark-grey))))

   ;; コンパイル結果 (nvim の Error / WarningMsg に対応)
   `(compilation-error   ((t (:foreground ,red :weight bold))))
   `(compilation-warning ((t (:foreground ,yellow-orange :weight bold))))
   `(compilation-info    ((t (:foreground ,blue))))))

;;;###autoload
(when (and (boundp 'custom-theme-load-path) load-file-name)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'asiimov)
;;; asiimov-theme.el ends here
