# macOS の Ghostty は .app の中にあり PATH に載らない。
# Linux ではパッケージが直接 PATH に入るため、そのときは何もしない
if ! command -v ghostty > /dev/null 2>&1 && [ -x /Applications/Ghostty.app/Contents/MacOS/ghostty ]; then
    alias ghostty="/Applications/Ghostty.app/Contents/MacOS/ghostty"
fi

alias config='${EDITOR:-vim} ~/.config/ghostty/config'

# dotfiles は bare repository として $HOME に直接展開している (symlink を張らない)。
# 通常の git はこの構成を見つけられないため、git-dir を明示する alias を用意する
if [ -d "$HOME/.dotfiles" ]; then
    alias dot='git --git-dir="$HOME/.dotfiles" --work-tree="$HOME"'
fi
