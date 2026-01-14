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
        firefox
        google-chrome
        ice-bar
        iterm2
        kitty
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
        bun
        # dev utilities
        asdf-vm
        gh
        git
        graphite-cli
        ripgrep
        # Mac App Store apps
        mas
      ];

      homebrew = {
        enable = true;
        onActivation = {
          autoUpdate = true;
          upgrade = true;
          cleanup = "none";
        };


        # Brew only apps, not supported by nix-darwin
        casks = [
          "ghostty"
          "github"
          "philips-hue-sync"
          "reminders-menubar"
          "tailscale-app"
        ];

        # Mac App Store apps managed via `mas`.
        # Add entries as: "App Name" = 1234567890;  # where the number is the App Store ID
        # Example IDs can be found with: mas search "App Name"
        masApps = {
        "Hand Mirror" = 1502839586;
        };
      };

      # Login items via System Events (creates macOS Login Items)
      system.activationScripts.extraActivation.text = ''
        ${openOnLogin { path = "/Applications/Nix Apps/1Password.app";  }}
        ${openOnLogin { path = "/Applications/Nix Apps/AeroSpace.app";  }}
        ${openOnLogin { path = "/Applications/Nix Apps/Ice.app";  }}
        ${openOnLogin { path = "/Applications/Nix Apps/Raycast.app";  }}
        ${openOnLogin { path = "/Applications/Nix Apps/Rectangle.app";  }}
        ${openOnLogin { path = "/Applications/Nix Apps/Shottr.app";  }}
        ${openOnLogin { path = "/Applications/Reminders MenuBar.app";  }}
        ${openOnLogin { path = "/Applications/Tailscale.app";  }}
      '';

      # macOS settings
      system.defaults.dock.autohide = true;
      system.defaults.dock.orientation = "left";
      system.defaults.dock.show-recents = false;
      system.defaults.dock.magnification = false;
      system.defaults.dock.autohide-time-modifier = 0.5;
      system.defaults.spaces.spans-displays = false;

      # fonts
      fonts.packages = with pkgs; [
        maple-mono.truetype
      ];
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
            home.file.".config/kitty".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.computer/kitty";
            home.file.".config/ghostty".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.computer/ghostty";

            programs.git = {
              enable = true;
              package = pkgs.gitFull;          # helper support
              settings.credential.helper = "osxkeychain";
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
                # Initialize Homebrew environment (needed for headers/libs and tools on Apple Silicon)
                if [ -x /opt/homebrew/bin/brew ]; then
                  eval "$(/opt/homebrew/bin/brew shellenv)"
                fi
                [ -f ~/.computer/zsh/evals.zsh ] && source ~/.computer/zsh/evals.zsh
                [ -f ~/.computer/zsh/aliases.zsh ] && source ~/.computer/zsh/aliases.zsh
                . "${pkgs.asdf-vm}/etc/profile.d/asdf-prepare.sh"

                # Ensure asdf-erlang builds link against Homebrew OpenSSL 3
                export KERL_CONFIGURE_OPTIONS="--without-javac --without-erl_interface --with-ssl=$ASDF_ERLANG_OPENSSL_DIR"
                export KERL_BUILD_DOCS=no
                export CPPFLAGS="-I$ASDF_ERLANG_OPENSSL_DIR/include ''${CPPFLAGS:-}"
                export LDFLAGS="-L$ASDF_ERLANG_OPENSSL_DIR/lib ''${LDFLAGS:-}"
                export PKG_CONFIG_PATH="$ASDF_ERLANG_OPENSSL_DIR/lib/pkgconfig:''${PKG_CONFIG_PATH:-}"
              '';
            };
          };
        }
      ];
    };
  };
}
