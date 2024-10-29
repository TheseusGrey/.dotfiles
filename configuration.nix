{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
    ];

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  services.xserver.videoDriver = "nvidia";

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false; # Enable this if there's issues waking the PC from sleep
    powerManagement.finegrained = false; # Should work on your GPU but disabled for now
    open = true; # Use Nvidia's open source driver, still in early development so we'll disable it for now
    nvidiaSettings = true; # Accesible via `nvidia-settings` command
  };

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sdc";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;

  programs.waybar.enable = true;
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Configure keymap in X11
  services.xserver = {
  
    layout = "us";
    xkbVariant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  environment.shells = with pkgs; [ zsh ] ; 
  users.defaultUserShell = pkgs.zsh;
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ashe = {
    isNormalUser = true;
    description = "Ashe";
    extraGroups = [ "networkmanager" "wheel" ];
    useDefaultShell = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.permittedInsecurePackages = [
    "electron-25.9.0"
  ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "obsidian"
  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    w3m
    git
    neovim
    fzf
    rofi
    gcc
    gnumake
    alacritty
    waybar
    firefox
    dolphin
    obsidian
    tmux
    tmuxifier
    ripgrep
    lua
    hyprpaper
    discord
    graphite-cli
    unzip
    nodePackages_latest.nodejs
    python3
    xclip
    wl-clipboard-x11
    nodePackages_latest.prettier
    rar
    pyright
    stylua
    nil
    typescript
    lua-language-server
    black
    rust-analyzer
    cargo
    rustup
    rustc
    yazi
    kitty
    minecraft
    ruby
    pandoc
    jekyll
    ferium
    swaynotificationcenter
    elf2uf2-rs
    flip-link
  ];

  environment.pathsToLink = [ "/share/zsh" ];
  programs.zsh.enable = true;
  programs.yazi.enable = true;

  programs.steam.enable = true;
  hardware.opentabletdriver.enable = true;

  # read documentation at man configuration.nix or on https://nixos.org/nixos/options.html before changing.
  system.stateVersion = "24.11"; # Did you read the comment?
  system.autoUpgrade.enable  = true;
  system.autoUpgrade.allowReboot  = true;
}
