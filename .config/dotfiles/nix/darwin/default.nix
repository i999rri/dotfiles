# nix-darwin-only system settings. Anything NixOS also understands lives in
# nix/shared/common.nix.
{ pkgs, username, ... }:
let
  aquaskk = pkgs.callPackage ../pkgs/aquaskk.nix { };
in
{
  imports = [ ../shared/common.nix ];

  # macOS puts administrators in @admin, not @wheel.
  nix.settings.trusted-users = [
    "root"
    "@admin"
  ];

  nix.gc = {
    automatic = true;
    interval = {
      Weekday = 0;
      Hour = 3;
      Minute = 0;
    };
    options = "--delete-older-than 30d";
  };

  # User-level settings (defaults, home) need to know whose account to touch.
  system.primaryUser = username;

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };

  environment.shells = with pkgs; [
    zsh
    bash
  ];

  # sudo は env_reset で環境を作り直すが、secure_path が未定義だと呼び出し元の
  # PATH をそのまま使う。ログインシェルには set-environment が
  # /run/current-system/sw/bin を通すものの、そこが欠けた PATH から呼ぶと
  # (例: nix-daemon.sh だけで PATH を直したシェル) darwin-rebuild が
  # command not found になる。secure_path を定義して、sudo 越しの PATH を
  # 呼び出し元に依存しない固定値にする。
  # nix-darwin は /etc/sudoers.d/ 以下を store への symlink として張る。実体は
  # 0444 で誰も書けないため、sudo の「書き込み可能な sudoers は読まない」検査を
  # 通る (既存の 10-nix-darwin-extra-config も同じ方式)。
  environment.etc."sudoers.d/20-secure-path".text = ''
    Defaults secure_path="/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  '';

  # sudo を指紋認証で通す。書き込み先は /etc/pam.d/sudo_local で、Apple が
  # そのために用意した include 先。sudo 本体の /etc/pam.d/sudo は OS の更新で
  # 上書きされるため、そちらには触らない。
  #
  # reattach が要るのは tmux のため。tmux のサーバはユーザーのブートストラップ
  # セッションから切り離されたところで動くので、そのままだと中の sudo が
  # 指紋を要求できず、パスワード入力に落ちる。
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # macOS の GUI アプリのうち、nixpkgs で素直に動くもの (ランチャーと
  # ターミナル) は nix で、そうでないもの (下記 Homebrew の項) は cask で
  # 管理する。Homebrew 本体は入れない。

  # macOS 専用の GUI アプリはここで管理する。nix/shared/packages.nix には
  # 入れない。あちらは OS を問わない CLI 環境の一覧で、GUI アプリが混ざる
  # 場所ではない。いずれも .app を持つパッケージで、switch すると
  # /Applications/Nix Apps/ 以下にリンクされる。
  #
  #   raycast      Spotlight の代わりに使うランチャー。OS のキーバインドを
  #                置き換える立ち位置にあるため、方針の例外として管理する
  #   ghostty-bin  常用しているターミナル。設定は .config/ghostty/config に
  #                あり、この環境の前提になっている。darwin では公式の
  #                ビルド済みバイナリ (ghostty-bin) を使う。ソースの ghostty
  #                は nixpkgs では Linux 専用
  environment.systemPackages = [
    pkgs.raycast
    pkgs.ghostty-bin
  ];

  # 入力メソッドだけは systemPackages に入れても意味がない。macOS が探すのは
  # /Library/Input Methods だけで、Nix のプロファイルは見に行かないため。
  #
  # しかも symlink では駄目で、実体の bundle でなければならない。macOS の
  # 入力メソッド登録は、ログイン時に /Library/Input Methods を走査するが、
  # symlink や /nix/store を指す登録はそこで無視される (セキュリティ上、
  # セッション内で動く入力メソッドは検証済みの実体しか受け付けない)。
  # そこで store から実体をコピーする。署名は notarized のまま保たれるので
  # Gatekeeper は通る。
  #
  # コピー済みかは、最後に展開した store パスをマーカーに記録して判定する。
  # マーカーが無いのに bundle があるときは、手で入れたものと見なして壊さない。
  # 反映にはログインし直しが要る (macOS が走査するのがそのタイミングのため)。
  system.activationScripts.postActivation.text = ''
    echo "installing input methods..." >&2
    aquaskkTarget='/Library/Input Methods/AquaSKK.app'
    aquaskkSource='${aquaskk}/Library/Input Methods/AquaSKK.app'
    aquaskkMarker='/Library/Input Methods/.aquaskk.nix-store'
    lsregister='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister'
    if [ -e "$aquaskkTarget" ] && [ ! -e "$aquaskkMarker" ]; then
      echo "warning: $aquaskkTarget は Nix 管理外。手で消してから switch する" >&2
    elif [ "$(cat "$aquaskkMarker" 2> /dev/null)" != "$aquaskkSource" ]; then
      rm -rf "$aquaskkTarget"
      cp -R "$aquaskkSource" "$aquaskkTarget"
      chmod -R u+w "$aquaskkTarget"
      printf '%s' "$aquaskkSource" > "$aquaskkMarker"
      "$lsregister" -f "$aquaskkTarget" || true
    fi

    # nix-darwin は GUI アプリを /Applications/Nix Apps/ に置く。この場所は
    # システムボリューム上なので Spotlight で index できるが、switch では
    # 再 index が促されず、Spotlight (と、それを使う Raycast) から引けない
    # ままになる。実体を指す /nix は別ボリュームで index 対象外のため、
    # trampoline 側を明示的に取り込ませる。
    if [ -d '/Applications/Nix Apps' ]; then
      echo "indexing /Applications/Nix Apps for Spotlight..." >&2
      /usr/bin/mdimport '/Applications/Nix Apps' || true
    fi
  '';

  # Homebrew 本体を宣言的にインストールする (flake input の nix-homebrew)。
  # これが無いと nix-darwin の homebrew.* は「brew が未導入」で activation を
  # 止めるため、手で公式インストーラを走らせる必要があった。これで初回の
  # switch が Homebrew の導入まで面倒を見る。
  #
  # enableRosetta は x86_64 の cask を Rosetta 2 経由で入れたいとき用。今の
  # cask はどれも arm64 ネイティブ / universal なので入れていない。
  nix-homebrew = {
    enable = true;
    user = username;
  };

  # nixpkgs に darwin 版の GUI が無い / あっても実用的でないアプリを、
  # Homebrew cask で宣言的に入れる。nix-darwin は Brewfile を生成して
  # brew bundle を走らせるだけ。Homebrew 本体の導入は上の nix-homebrew が担う。
  #
  #   firefox        firefox-bin は動くが、ブラウザは /Applications 直下に
  #                  ある前提で自己更新する。cask の方が素直
  #   1password      /Applications 直下にある前提でブラウザ拡張と system
  #                  authentication の署名検証をする。/nix/store から動かすと
  #                  連携が壊れるため cask
  #   tailscale-app  nixpkgs の tailscale は CLI/daemon だけで、メニューバーの
  #                  GUI (Network Extension 込み) は cask にしか無い。CLI 名の
  #                  tailscale から改名されて -app が付いた
  #   windows-app    nixpkgs に無い。Microsoft Remote Desktop の後継
  #   zen            nixpkgs に無い (macOS は DMG 配布のみ)。Firefox 系の
  #                  ブラウザで、cask が auto_updates 対応なので自己更新とも
  #                  衝突しない
  #
  # 既に /Applications に手で入れたものがあると brew bundle が衝突するので、
  # 初回だけ手で adopt して brew の管理下に置く (下記 setup 手順)。
  homebrew = {
    enable = true;

    casks = [
      "firefox"
      "1password"
      "tailscale-app"
      "windows-app"
      "zen"
    ];

    onActivation = {
      # switch のたびに brew 自身と cask 一覧を更新し、古い cask は入れ替える
      autoUpdate = true;
      upgrade = true;

      # ここに書いていない cask やアプリには触らない (勝手に消さない)。
      # 宣言した一覧だけを厳密にするなら "uninstall" にする
      cleanup = "none";
    };
  };

  # 「システム設定」で手を入れた項目だけを書く。macOS の初期値と同じものは
  # 書かない (書くと差分が「意思のある設定」なのか「たまたま既定値」なのか
  # 区別できなくなるため)。適用先は system.primaryUser のアカウント。
  #
  # nix-darwin は書いた項目に defaults write を撃つだけで、消した項目に
  # defaults delete は撃たない。つまりここから項目を消しても、一度反映した
  # マシンでは値が残る (新しいマシンでは書かれないので初期値になる)。既に
  # 書いてしまった値を戻すには、手で defaults delete する必要がある。
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";

      # ナチュラルスクロールを切る (false = 従来向き。指を下ろすと中身も下)。
      # macOS の既定は true なので、明示的に書いておかないと既定に戻る
      "com.apple.swipescrolldirection" = false;

      # トラックパッドの軌跡の速さ。0〜3 で、3 が一番速い
      "com.apple.trackpad.scaling" = 3.0;

      # キーリピートを最速に。nvim でのカーソル移動が効いてくる
      InitialKeyRepeat = 15;
      KeyRepeat = 2;

      # 入力に勝手に手を入れる機能を全部止める。特にスマート引用符は、
      # コードやコマンドを書くときに " を “ ” に化けさせて壊す
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticCapitalizationEnabled = false;
    };

    dock = {
      autohide = true;
      orientation = "left";
      tilesize = 22;
      magnification = false;

      # Dock に並べるものを固定する。ここに書いたものが並び順そのものになり、
      # 初期状態で入っている Mail や Music などは消える (Finder とゴミ箱は
      # Dock の両端に固定されているものなので、この一覧の管轄外)。
      #
      # Ghostty は Nix で入れているため /Applications/Nix Apps/ に置かれる。
      # 中身は /nix/store を指すが、この trampoline のパス自体は世代をまたいで
      # 変わらないので Dock から直に指してよい。Spotlight は /nix を index
      # しないので Raycast や Spotlight からは引けず、Dock に置くのが手軽。
      # 残りは Nix の管理外で入れたアプリで、こちらもパスを直に書いている。
      persistent-apps = [
        "/Applications/Firefox.app"
        "/Applications/Nix Apps/Ghostty.app"
        "/Applications/1Password.app"
        "/Applications/Tailscale.app"
        "/Applications/Windows App.app"
      ];
    };

    # 時計は「曜日 + 12時間表記」。日付は出さない (0 = 表示しない)
    menuExtraClock = {
      ShowAMPM = true;
      ShowDate = 0;
      ShowDayOfWeek = true;
    };

    # キーボードショートカット。nix-darwin に専用のオプションが無いので
    # plist を直に書く。
    #
    # parameters は (文字の ASCII コード, キーコード, 修飾キーのビットマスク)。
    # 65535 は「文字なし」を表す。値はどれも システム設定 で実際に割り当てて
    # macOS 自身に書かせたものを写しているので、配列の解釈で外すことがない。
    CustomUserPreferences."com.apple.symbolichotkeys".AppleSymbolicHotKeys = {
      # 前の入力ソースを選択: ⌃Space -> ⌘`
      # 96 = `、50 = ` のキーコード、1048576 = Command
      "60" = {
        enabled = 1;
        value = {
          parameters = [
            96
            50
            1048576
          ];
          type = "standard";
        };
      };

      # 入力ソースが 2 つしかないので「次の入力ソース」(⌥⌃Space) は要らない
      "61".enabled = 0;

      # 「次のウインドウを操作対象にする」の既定が ⌘` で、上と衝突する。
      # この辞書は defaults write で丸ごと置換されるため、ここに書かないと
      # 既定値が復活してぶつかる
      "27".enabled = 0;

      # Spotlight (⌘Space) を外して、同じキーを Raycast に渡す。
      # 止まるのはショートカットだけで、検索インデックス自体は動いたまま
      "64".enabled = 0;
    };

    # デスクトップに置いたものを表示しない。壁紙だけの状態にする
    WindowManager = {
      HideDesktop = true;
      StandardHideDesktopIcons = true;
    };
  };

  system.stateVersion = 6;
}
