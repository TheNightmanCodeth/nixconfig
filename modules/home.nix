# joe's home-manager config, identical on both machines.
{ config, lib, pkgs, ... }:
{
  # Ported from the zsh-snap ~/.zshrc and ~/.zprofile.
  programs.zsh = {
    enable = true;

    # The old ~/.zprofile, verbatim. All macOS-specific, so ithaca only.
    # home-manager owns ~/.zprofile now and it's read-only: installers that try
    # to append to it (pipx, swiftly, …) will fail. Add their lines here.
    profileExtra = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin ''
      eval "$(/opt/homebrew/bin/brew shellenv)"

      # Setting PATH for Python 3.13
      PATH="/Library/Frameworks/Python.framework/Versions/3.13/bin:''${PATH}"
      export PATH

      # Added by swiftly
      . "/Users/joe/.swiftly/env.sh"
      # Created by `pipx` on 2025-12-22 19:38:51
      export PATH="$PATH:/Users/joe/.local/bin"

      export PATH=/Users/joe/.opencode/bin:$PATH
      export PATH=/Users/joe/.scripts:$PATH

      # Mint
      MINT_PATH=$HOME/.mint/bin
      export PATH="$MINT_PATH:$PATH"

      # little-coder (pi)
      export LLAMACPP_BASE_URL=http://odysseus.jdiggity.me:8080/v1
      export LLAMACPP_API_KEY=noop

      # Auto patch (tweakcc) claude on update
      claude() {
        local stamp="$HOME/.local/share/claude/.catppuccin-patched"
        local current
        current=$(readlink "$HOME/.local/bin/claude" 2>/dev/null)

        if [[ "$current" != "$(cat "$stamp" 2>/dev/null)" ]]; then
          echo '[catppuccin-auto] new Claude version, re-applying patch...'
          printf 'Y\n' | npx tweakcc adhoc-patch \
            --script "@$HOME/Projects/cc-catppuccin/catppuccin-auto-patch.js" \
            2>&1 | tail -1
          printf '%s\n' "$current" > "$stamp"
        fi

        command claude "$@"
      }
    '';

    antidote = {
      enable = true;
      # HM loads antidote (mkOrder 550) *before* its compinit (mkOrder 570).
      # zsh-completions only needs to be on fpath by then, which is fine. But
      # fzf-tab has to come after compinit, and the widget-wrapping plugins after
      # fzf-tab, so those three are deferred. zsh-defer runs them in list order
      # once .zshrc finishes, so the relative order is the same as before.
      plugins = [
        "zsh-users/zsh-completions kind:fpath path:src"
        "rupa/z"
        "ael-code/zsh-colored-man-pages"
        "momo-lab/zsh-abbrev-alias"
        "fdellwing/zsh-bat"
        "sindresorhus/pure kind:fpath"
        "Aloxaf/fzf-tab kind:defer"
        "zsh-users/zsh-autosuggestions kind:defer"
        # Must stay last.
        "zsh-users/zsh-syntax-highlighting kind:defer"
      ];
    };

    initContent = ''
      # Map UP and DOWN to natively cycle past commands matching what is typed so far
      bindkey '^[[A' history-beginning-search-backward
      bindkey '^[[B' history-beginning-search-forward

      autoload -Uz promptinit && promptinit && prompt pure

      # fnm
      FNM_PATH="/opt/homebrew/opt/fnm/bin"
      if [ -d "$FNM_PATH" ]; then
        eval "$(fnm env --shell zsh)"
      fi
    '';
  };

  # Runtime dependencies of fzf-tab and zsh-bat.
  home.packages = [
    pkgs.fzf
    pkgs.bat
  ];

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "TheNightmanCodeth";
        email = "joseph.diragi@icloud.com";
        signingkey = "~/.ssh/id_ed25519.pub";
      };
      commit.gpgsign = true;
      gpg.format = "ssh";
      gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  # Lets git verify SSH-signed commits locally (ithaca, odysseus).
  xdg.configFile."git/allowed_signers".text = ''
    joseph.diragi@icloud.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGmW6OuZ1gSgM6ubqbE5ZWVqe/Ay/W3j4XhGnaB9folp
    joseph.diragi@icloud.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJeBvmFRJHthe3AgBdjUspBcVxEm9ODjErePP0+bFwJ9
  '';

  # First home-manager generation on both machines. Same rule as
  # system.stateVersion: a marker, not something to keep current.
  home.stateVersion = "26.05";
}
