{ pkgs, ... }:
let
  accent = "flamingo";
  flavor = "macchiato";
in {
  catppuccin.flavor = flavor;
  catppuccin.enable = true;

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

    kitty = {
      enable = true;
      settings = {
        font_family = "BerkeleyMono Nerd Font Mono";
        bold_font = "BerkeleyMono Nerd Font Mono Bold";
        bold_italic_font = "BerkeleyMono Nerd Font Bold Italic";
        italic_font = "BerkeleyMono Nerd Font Italic";
        wayland_titlebar_color = "background";
        window_padding_width = 10;
      };
      catppuccin = {
        enable = true;
        inherit flavor;
      };
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

  gtk = {
    enable = true;
    catppuccin = {
      enable = true;
      inherit accent flavor;
      gnomeShellTheme = true;
      icon = {
        enable = true;
        inherit accent flavor;
      };
    };
  };

  home = {
    packages = with pkgs; [
      zed-editor
      hyprland
      waybar
    ];

    username = "joe";
    homeDirectory = "/home/joe";

    stateVersion = "24.11";
  };
}
