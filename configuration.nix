{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
      <home-manager/nixos>
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
    open = false; # Use Nvidia's open source driver, still in early development so we'll disable it for now
    nvidiaSettings = true; # Accesible via `nvidia-settings` command
    package = config.boot.kernelPackages.nvidiaPackages.stable;
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
  programs.hyprland.enable = true;
  programs.waybar.enable = true;
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

  fonts.fontDir.enable = true;

  environment.systemPackages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    git
    neovim
    fzf
    rofi
    alacritty
    waybar
    firefox
    tmux
    tmuxifier
    home-manager
  ];

  environment.pathsToLink = [ "/share/zsh" ];
  programs.zsh.enable = true;
  programs.steam.enable = true;

  # read documentation at man configuration.nix or on https://nixos.org/nixos/options.html before changing.
  system.stateVersion = "24.11"; # Did you read the comment?
}
