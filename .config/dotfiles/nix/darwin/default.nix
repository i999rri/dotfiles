# nix-darwin-only system settings. Anything NixOS also understands lives in
# nix/shared/common.nix.
{ pkgs, username, ... }:
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

  # Homebrew is left alone on purpose: .zshrc already sources it when present,
  # and the casks on a Mac are GUI apps that Nix has no business managing here.

  # 「システム設定」で手を入れた項目だけを書く。macOS の初期値と同じものは
  # 書かない (書くと差分が「意思のある設定」なのか「たまたま既定値」なのか
  # 区別できなくなるため)。適用先は system.primaryUser のアカウント。
  #
  # 消して switch すると、手で変える前の値ではなく OS の初期値に戻る。
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";

      # ナチュラルスクロールを切る (指の向き = コンテンツの向き、ではなく
      # 指の向き = スクロールバーの向き)
      "com.apple.swipescrolldirection" = false;

      # キーリピートを最速に。nvim でのカーソル移動が効いてくる
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };

    dock = {
      autohide = true;
      orientation = "left";
      tilesize = 22;
      magnification = false;
    };

    # 時計は「曜日 + 12時間表記」。日付は出さない (0 = 表示しない)
    menuExtraClock = {
      ShowAMPM = true;
      ShowDate = 0;
      ShowDayOfWeek = true;
    };

    # デスクトップに置いたものを表示しない。壁紙だけの状態にする
    WindowManager = {
      HideDesktop = true;
      StandardHideDesktopIcons = true;
    };
  };

  system.stateVersion = 6;
}
