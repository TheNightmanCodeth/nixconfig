{ pkgs, ... }:
let
  accent = "flamingo";
  flavor = "macchiato";
in {

  programs = {
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    eza = {
      enable = true;
      icons = true;
      git = true;
      enableZshIntegration = true;
    };

    neovim =  
      let  
        toLua = str: "lua << EOF\n${str}\nEOF\n";
        toLuaFile = file: "lua << EOF\n${builtins.readFile file}\nEOF\n";
      in {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;
        catppuccin = {
          enable = true;
          inherit flavor;
        };

        extraPackages = with pkgs; [
          lua-language-server
          nil
          rust-analyzer

          xclip
          wl-clipboard
        ];

        plugins = with pkgs.vimPlugins; [
          nvim-web-devicons
          plenary-nvim
          nui-nvim
          {
            plugin = catppuccin-nvim;
            config = toLua "require(\"catppuccin\").setup()";
          }

          {
            plugin = gitsigns-nvim;
            config = toLua "require(\"gitsigns\").setup()";
          }

          {
            plugin = nvim-lspconfig;
            config = toLuaFile ./neovim/plugins/lsp.lua;
          }

          neodev-nvim

          {
            plugin = neo-tree-nvim;
            config = toLuaFile ./neovim/plugins/neotree.lua;
          }

          nvim-cmp
          {
            plugin = nvim-cmp;
            config = toLuaFile ./neovim/plugins/cmp.lua;
          }

          {
            plugin = telescope-nvim;
            config = toLuaFile ./neovim/plugins/telescope.lua;
          }

          telescope-fzf-native-nvim

          cmp_luasnip
          cmp-nvim-lsp

          luasnip
          friendly-snippets

          lualine-nvim

          {
            plugin = (nvim-treesitter.withPlugins (p: [
              p.tree-sitter-nix
              p.tree-sitter-vim
              p.tree-sitter-bash
              p.tree-sitter-lua
              p.tree-sitter-zig
              p.tree-sitter-yaml
              p.tree-sitter-rust
              p.tree-sitter-python
              p.tree-sitter-markdown
              p.tree-sitter-just
              p.tree-sitter-json
              p.tree-sitter-gleam
              p.tree-sitter-elixir
            ]));
            config = toLuaFile ./neovim/plugins/treesitter.lua;
          }

          vim-nix
        ];

        extraLuaConfig = ''
          ${builtins.readFile ./neovim/options.lua}
        '';
      };

      carapace = {
        enable = true;
        enableNushellIntegration = true;
      };

      zsh = {
        enable = true;
        zplug = {
          enable = true;
          plugins = [
            { name = "zsh-users/zsh-autosuggestions"; }
            { name = "romkatv/powerlevel10k"; tags = [ "as:theme" "depth:1" ]; }
          ];
        };
        initExtra = ''
          test -f ~/.p10k.zsh && source ~/.p10k.zsh
        '';
      };
  };

    #gtk = {
    #  enable = true;
    #  catppuccin = {
    #    enable = true;
    #    inherit accent flavor;
    #    gnomeShellTheme = true;
    #      #icon = {
    #      #  enable = true;
    #      #  inherit accent flavor;
    #      #};
    #  };
    #};

  dconf = {
    enable = true;
    settings = {
      "org/gnome/shell" = {
        disable-user-extensions = false;
        ## GNOME EXTENSIONS ##
        enabled-extensions = with pkgs.gnomeExtensions; [
          dash-to-dock.extensionUuid
          blur-my-shell.extensionUuid
        ];
      };
      "org/gnome/epiphany" = {
        "web/enable-webextensions" = true;
      };
    };
  };

  home = {
    packages = with pkgs; [
      zed-editor
      gnomeExtensions.dash-to-dock
      gnomeExtensions.blur-my-shell
    ];

    username = "joe";
    homeDirectory = "/home/joe";

    stateVersion = "24.11";
  };
}
