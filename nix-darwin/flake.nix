{
  description = "KPM nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

  };
  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, ... }:
  let
    helpers = import ./lib/helpers.nix { };
    openOnLogin = helpers.openOnLogin;
    configuration = { pkgs, ... }: {
      system.primaryUser = "kyle";
      users.users.kyle = {
        home = "/Users/kyle";
        shell = pkgs.zsh;
      };

      nix.settings.experimental-features = [ "nix-command" "flakes" ];
      system.configurationRevision = self.rev or self.dirtyRev or null;
      system.stateVersion = 6;

      nixpkgs = {
        hostPlatform = "aarch64-darwin";
        config.allowUnfree = true;
      };

      environment.systemPackages = with pkgs; [
        # apps
        _1password-gui
        aerospace
        chatgpt
        code-cursor
        google-chrome
        iterm2
        obsidian
        postman
        raycast
        rectangle
        shottr
        slack
        # terminal
        neovim
        oh-my-posh
        oh-my-zsh
        zoxide
        # dev utilities
        asdf-vm
        gh
        git
        graphite-cli
        openssl
      ];

      homebrew = {
        enable = true;
        onActivation = {
          autoUpdate = true;
          upgrade = true;
          cleanup = "uninstall";
        };

        # Brew only apps, not supported by nix-darwin
        casks = [
          "github"
          "hyperkey"
          "reminders-menubar"
        ];
      };

      # Login items via System Events (creates macOS Login Items)
      system.activationScripts.extraActivation.text = ''
        ${openOnLogin { path = "/Applications/Nix Apps/1Password.app";  }}
        ${openOnLogin { path = "/Applications/Nix Apps/AeroSpace.app";  }}
        ${openOnLogin { path = "/Applications/Nix Apps/Raycast.app";  }}
        ${openOnLogin { path = "/Applications/Nix Apps/Rectangle.app";  }}
        ${openOnLogin { path = "/Applications/Nix Apps/Shottr.app";  }}
        ${openOnLogin { path = "/Applications/Reminders MenuBar.app";  }}
        ${openOnLogin { path = "/Applications/Hyperkey.app";  }}
      '';

      # macOS settings
      system.defaults.dock.autohide = true;
      system.defaults.dock.orientation = "left";
      system.defaults.dock.show-recents = false; 
      system.defaults.dock.magnification = false;
      system.defaults.dock.autohide-time-modifier = 0.5;
      system.defaults.spaces.spans-displays = false;
    };
  in {
    darwinConfigurations.kpm = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        configuration

        # Wire in Home Manager on macOS
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          # Your Home Manager user config (dotfiles-level, per-user)
          home-manager.users.kyle = { pkgs, config, ... }: {
            home.stateVersion = "24.05";

            home.file.".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.computer/nvim";
            home.file.".aerospace.toml".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.computer/aerospace/config.toml";

            programs.git = {
              enable = true;
              package = pkgs.gitAndTools.gitFull;          # helper support
              extraConfig.credential.helper = "osxkeychain";
            };

            programs.zsh = {
              enable = true;

              # These are Home Manager options (not nix-darwin)
              enableCompletion = true;
              autosuggestion.enable = true;   
              syntaxHighlighting.enable = true;

              oh-my-zsh = {
                enable = true;
                theme = "agnoster"; 
                plugins = [ "git" "npm" "history" "node" ];
              };
              
              initContent = ''
                export PATH="/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:$PATH"
                [ -f ~/.computer/zsh/evals.zsh ] && source ~/.computer/zsh/evals.zsh
                [ -f ~/.computer/zsh/aliases.zsh ] && source ~/.computer/zsh/aliases.zsh
                 . "${pkgs.asdf-vm}/share/asdf-vm/asdf.sh"
                autoload -Uz bashcompinit && bashcompinit
                . "${pkgs.asdf-vm}/share/asdf-vm/completions/asdf.bash"
              '';
            };
          };
        }
      ];
    };
  };
}