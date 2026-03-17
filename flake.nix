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
            git
          ];

          programs.zsh.enable = true;

          system.primaryUser = "pseudomac";

          programs.ssh.extraConfig = "Host github\n  HostName github.com\n  User git\n  IdentityFile ~/.ssh/id_ed25519_pseudomac-host\n  IdentitiesOnly yes";

          system.keyboard.enableKeyMapping = true;
          system.keyboard.nonUS.remapTilde = true;

          system.defaults.dock = {
            autohide = true;
            showhidden = true;
            tilesize = 42;
          };

          system.defaults.controlcenter = {
            BatteryShowPercentage = true;
            Sound = true;
          };

          system.defaults.loginwindow.GuestEnabled = false;

          system.defaults.menuExtraClock = {
            ShowSeconds = true;
            ShowDate = 2;
            ShowDayOfWeek = false;
            Show24Hour = true;
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
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#RJs-MacBook-Pro
      darwinConfigurations."RJs-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        modules = [ configuration ];
      };
    };
}
