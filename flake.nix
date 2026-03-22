{
  description = "Pseudo nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
    }:
    let
      configuration =
        { pkgs, ... }:
        {
          nixpkgs.config.allowUnfree = true;

          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = with pkgs; [
            neovim
            brave
            #
            #`shell = {program = "/run/current-system/sw/bin/zsh"}` in configuration file of alacritty ~/.config/alacritty/alacritty.toml
            # alacritty migrate
            alacritty
            #
            vscodium
            nixfmt
            tmux
            qbittorrent
            podman
            podman-compose
            battery-toolkit
            appflowy
            vlc-bin
            slack
          ];
          
          # TODO: Test and enable/delete
          # environment.shellAliases = {
          #   podshell = "podman exec -it";
          # };

          programs.zsh = {
            # Common options (both platforms)
            enable = true;
            enableCompletion = true;

            promptInit = ''
              autoload -U promptinit
              promptinit
              prompt off

              function git_branch_name() {
                branch=$(git symbolic-ref HEAD --short 2>/dev/null)
                if [ ! -z "$branch" ]; then
                  echo -n " [%F{red}$branch%f]"
                fi
              }

              # Omit username, print hostname + '$' with red when root, otherwise green:
              # https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html
              prompt='[%(!.%F{red}.%F{green})%m%f:%F{blue}%~%f]$(git_branch_name) %(!.%F{red}#%f.$) '

              # See: https://zsh.sourceforge.io/Doc/Release/Options.html#Prompting
              setopt prompt_cr    # print carriage return before printing a prompt in line editor
              setopt prompt_sp    # attempt to preserve partial lines using ansi control chars
              setopt prompt_subst # perform {parameter, command, arithmetic} expansion in prompts

              export PROMPT_EOL_MARK="" # don't show end-of-line marker on partial lines
            '';

            interactiveShellInit = ''
              # Enable bash completion compatibility
              autoload -U bashcompinit && bashcompinit

              # Disable ^S and ^Q flow control
              unsetopt FLOW_CONTROL

              # Copy-paste
              bindkey '^U' kill-whole-line
              bindkey '^Y' yanke

              # Syntax highlighting (must be sourced last)
              ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
              source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
            '';
          };

          system.primaryUser = "pseudogode";

          programs.ssh.extraConfig = "Host github\n  HostName github.com\n  User git\n  IdentityFile ~/.ssh/id_ed25519_macpcpc_host\n  IdentitiesOnly yes";

          system.startup.chime = false;

          system.defaults = {
            dock = {
              autohide = true;
              showhidden = true;
              tilesize = 42;
              persistent-apps = [
                "/Applications/Nix Apps/Brave Browser.app"
                "/Applications/Nix Apps/Alacritty.app"
                "/Applications/Nix Apps/AppFlowy.app"
              ];
            };

            controlcenter = {
              BatteryShowPercentage = true;
              Sound = true;
            };

            menuExtraClock = {
              ShowSeconds = true;
              ShowDate = 2;
              ShowDayOfWeek = false;
              Show24Hour = true;
            };

            finder = {
              _FXShowPosixPathInTitle = true;
              AppleShowAllExtensions = true;
              AppleShowAllFiles = true;
              ShowPathbar = true;
              ShowStatusBar = false;
            };

            loginwindow.GuestEnabled = false;
            NSGlobalDomain.AppleInterfaceStyle = "Dark";
            NSGlobalDomain.AppleInterfaceStyleSwitchesAutomatically = false;
            NSGlobalDomain.KeyRepeat = 2;
          };

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Enable alternative shell support in nix-darwin.
          # programs.fish.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 6;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";

          launchd.user.agents.battery-toolkit = {
            serviceConfig = {
              RunAtLoad = true;
              KeepAlive = false;
            };

            script = ''
              open -a "Battery Toolkit"
            '';
          };
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#macpcpc
      darwinConfigurations.macpcpc = nix-darwin.lib.darwinSystem {
        modules = [ configuration ];
      };
    };
}
